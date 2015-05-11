require 'RMagick'
require 'forwardable'
require_relative 'thumbnailer/images'

module Plugin
	module Thumbnailer
		class UnsupportedMethodError < ArgumentError
			def initialize(method)
				super("thumbnail method '#{method}' is not supported")
			end
		end

		class UnsupportedEditError < ArgumentError
			def initialize(name)
				super("no edit with name '#{name}' is supported")
			end
		end

		class UnsupportedMediaTypeError < ArgumentError
			def initialize(error)
				super("unsupported media type: #{error}")
			end
		end

		class ImageTooLargeError < ArgumentError
			def initialize(error)
				super("image too large: #{error}")
			end
		end

		class ZeroSizedImageError < ArgumentError
			def initialize(width, height)
				super("at least one image dimension is zero: #{width}x#{height}")
			end
		end

		class InvalidColorNameError < ArgumentError
			def initialize(color)
				super("invalid color name: #{color}")
			end
		end

		class Service
			include ClassLogging

			extend Stats
			def_stats(
				:total_images_loaded,
				:total_images_reloaded,
				:total_images_downscaled,
				:total_thumbnails_created,
				:images_loaded,
				:max_images_loaded,
				:max_images_loaded_worker,
				:total_images_created,
				:total_images_destroyed,
				:total_images_created_from_blob,
				:total_images_created_initialize,
				:total_images_created_resize,
				:total_images_created_crop,
				:total_images_created_sample,
				:total_images_created_blur_image,
				:total_images_created_composite
			)

			def self.input_formats
				Magick.formats.select do |name, mode|
					mode.include? 'r'
				end.keys.map(&:downcase)
			end

			def self.output_formats
				Magick.formats.select do |name, mode|
					mode.include? 'w'
				end.keys.map(&:downcase)
			end

			def self.rmagick_version
				Magick::Version
			end

			def self.magick_version
				Magick::Magick_version
			end

			def initialize(options = {})
				@thumbnailing_methods = {}
				@edits = {}
				@options = options
				@images_loaded = 0

				log.info "initializing thumbnailer: #{self.class.rmagick_version} #{self.class.magick_version}"

				set_limit(:area, options[:limit_area]) if options.member?(:limit_area)
				set_limit(:memory, options[:limit_memory]) if options.member?(:limit_memory)
				set_limit(:map, options[:limit_map]) if options.member?(:limit_map)
				set_limit(:disk, options[:limit_disk]) if options.member?(:limit_disk)

				Magick.trace_proc = lambda do |which, description, id, method|
					case which
					when :c
						Service.stats.incr_images_loaded
						@images_loaded += 1
						Service.stats.max_images_loaded = Service.stats.images_loaded if Service.stats.images_loaded > Service.stats.max_images_loaded
						Service.stats.max_images_loaded_worker = @images_loaded if @images_loaded > Service.stats.max_images_loaded_worker
						Service.stats.incr_total_images_created
						case method
						when :from_blob
							Service.stats.incr_total_images_created_from_blob
						when :initialize
							Service.stats.incr_total_images_created_initialize
						when :resize
							Service.stats.incr_total_images_created_resize
						when :resize!
							Service.stats.incr_total_images_created_resize
						when :crop
							Service.stats.incr_total_images_created_crop
						when :crop!
							Service.stats.incr_total_images_created_crop
						when :sample
							Service.stats.incr_total_images_created_sample
						when :blur_image
							Service.stats.incr_total_images_created_blur_image
						when :composite
							Service.stats.incr_total_images_created_composite
						else
							log.warn "uncounted image creation method: #{method}"
						end
					when :d
						Service.stats.decr_images_loaded
						@images_loaded -= 1
						Service.stats.incr_total_images_destroyed
					end
					log.debug{"image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{Service.stats.images_loaded}"}
				end
			end

			def load(io, options = {}, &block)
				mw = options[:max_width]
				mh = options[:max_height]
				if mw and mh
					mw = mw.to_i
					mh = mh.to_i
					log.info "using max size hint of: #{mw}x#{mh}"
				end

				begin
					blob = io.read

					old_memory_limit = nil
					borrowed_memory_limit = nil
					if options.member?(:limit_memory)
						borrowed_memory_limit = options[:limit_memory].borrow(options[:limit_memory].limit, 'image magick')
						old_memory_limit = set_limit(:memory, borrowed_memory_limit)
					end

					images = Magick::Image.from_blob(blob) do |info|
						if mw and mh
							define('jpeg', 'size', "#{mw*2}x#{mh*2}")
							define('jbig', 'size', "#{mw*2}x#{mh*2}")
						end
					end

					image = images.first
					if image.columns > image.base_columns or image.rows > image.base_rows and not options[:no_reload]
						log.warn "input image got upscaled from: #{image.base_columns}x#{image.base_rows} to #{image.columns}x#{image.rows}: reloading without max size hint!"
						images.each do |other|
							other.destroy!
						end
						images = Magick::Image.from_blob(blob)
						Service.stats.incr_total_images_reloaded
					end
					blob = nil

					image = images.shift
					begin
						images.each do |other|
							other.destroy!
						end
						log.info "loaded image: #{image.inspect}"
						Service.stats.incr_total_images_loaded

						# clean up the image
						image.strip!
						image.properties do |key, value|
							log.debug "deleting user propertie '#{key}'"
							image[key] = nil
						end

						if mw and mh and not options[:no_downscale]
							f = image.find_downscale_factor(mw, mh)
							if f > 1
								image = image.downscale(f)
								log.info "downscaled image by factor of #{f}: #{image.inspect}"
								Service.stats.incr_total_images_downscaled
							end
						end
						image.get do |image|
							yield InputImage.new(image, @thumbnailing_methods, @edits)
							true # make sure it is destroyed
						end
					rescue
						image.destroy!
						raise
					end
				rescue Magick::ImageMagickError => error
					raise ImageTooLargeError, error if error.message =~ /cache resources exhausted/
					raise UnsupportedMediaTypeError, error
				ensure
					if old_memory_limit
						set_limit(:memory, old_memory_limit)
						options[:limit_memory].return(borrowed_memory_limit, 'image magick')
					end
				end
			end

			def thumbnailing_method(method, &impl)
				log.info "adding thumbnailing method: #{method}"
				@thumbnailing_methods[method] = impl
			end

			def edit(name, &impl)
				log.info "adding edit: #{name}(#{impl.parameters.drop(1).map{|p| p.last.to_s}.join(', ')})"
				@edits[name] = impl
			end

			def set_limit(limit, value)
				old = Magick.limit_resource(limit, value)
				log.info "changed #{limit} limit from #{old} to #{value} bytes"
				old
			end

			def setup_default_methods
				thumbnailing_method('crop') do |image, width, height, options|
					image.resize_to_fill(width, height, (Float(options['float-x']) rescue 0.5), (Float(options['float-y']) rescue 0.5)) if image.columns != width or image.rows != height
				end

				thumbnailing_method('fit') do |image, width, height, options|
					image.resize_to_fit(width, height) if image.columns != width or image.rows != height
				end

				thumbnailing_method('pad') do |image, width, height, options|
					image.resize_to_fit(width, height).get do |resize|
						resize.render_on_background(options['background-color'], width, height, (Float(options['float-x']) rescue 0.5), (Float(options['float-y']) rescue 0.5))
					end if image.columns != width or image.rows != height
				end

				thumbnailing_method('limit') do |image, width, height, options|
					image.resize_to_fit(width, height) if image.columns > width or image.rows > height
				end
			end

			def setup_default_edits
				edit('cut') do |image, x, y, width, height|
					x = x.to_f
					y = y.to_f
					width = width.to_f
					height = height.to_f

					x ||= 0.25
					y ||= 0.25
					width ||= 0.5
					height ||= 0.5

					image.crop(x * image.columns, y * image.rows, width * image.columns, height * image.rows, true) if image.columns != width or image.rows != height
				end
			end
		end

		def self.setup(app)
			Service.logger = app.logger_for(Service)
			InputImage.logger = app.logger_for(InputImage)
			Thumbnail.logger = app.logger_for(Thumbnail)

			@@service = Service.new(
				limit_memory: app.settings[:limit_memory],
				limit_map: app.settings[:limit_map],
				limit_disk: app.settings[:limit_disk]
			)

			@@service.setup_default_methods
			@@service.setup_default_edits
		end

		def self.setup_plugins(plugins)
			plugins.map(&:thumbnailing_methods).flatten(1).each do |name, block|
				@@service.thumbnailing_method(name, &block)
			end
		end

		def thumbnailer
			@@service
		end
	end
end

