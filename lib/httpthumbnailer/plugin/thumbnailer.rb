require 'RMagick'
require 'raindrops'
require 'forwardable'

module Plugin
	module Thumbnailer
		class UnsupportedMethodError < ArgumentError
			def initialize(method)
				super("thumbnail method '#{method}' is not supported")
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

		module ImageProcessing
			def replace
				@use_count ||= 0
				processed = nil
				begin
					processed = yield self
					processed = self unless processed
					fail 'got destroyed image' if processed.destroyed?
				ensure
					self.destroy! if @use_count <= 0 if processed != self
				end
				processed
			end

			def use
				@use_count ||= 0
				@use_count += 1
				begin
					yield self
					self
				ensure
					@use_count -=1
					self.destroy! if @use_count <= 0
				end
			end
		end

		class InputImage
			include ClassLogging
			extend Forwardable

			def initialize(image, processing_methods, options = {})
				@image = image
				@processing_methods = processing_methods
			end

			def thumbnail(spec)
				spec = spec.dup
				# default backgraud is white
				spec.options['background-color'] = spec.options.fetch('background-color', 'white').sub(/^0x/, '#')

				width = spec.width == :input ? @image.columns : spec.width
				height = spec.height == :input ? @image.rows : spec.height

				raise ZeroSizedImageError.new(width, height) if width == 0 or height == 0

				begin
					process_image(spec.method, width, height, spec.options).replace do |image|
						if image.alpha?
							log.info 'thumbnail has alpha, rendering on background'
							image.render_on_background(spec.options['background-color'])
						end
					end.use do |image|
						Service.stats.incr_total_thumbnails_created
						image_format = spec.format == :input ? @image.format : spec.format

						yield Thumbnail.new(image, image_format, spec.options)
					end
				rescue Magick::ImageMagickError => error
					raise ImageTooLargeError, error.message if error.message =~ /cache resources exhausted/
					raise
				end
			end

			def process_image(method, width, height, options)
				@image.replace do |image|
					impl = @processing_methods[method] or raise UnsupportedMethodError, method
					impl.call(image, width, height, options)
				end
			end

			# behave as @image in processing
			def use
				@image.use do |image|
					yield self
				end
			end

			def_delegators :@image, :destroy!, :destroyed?, :mime_type

			# needs to be seen as @image when returned in replace block
			def ==(image)
				super image or @image == image
			end
		end

		class Thumbnail
			include ClassLogging

			def initialize(image, format, options = {})
				@image = image
				@format = format
				@quality = (options['quality'] or default_quality(format))
				@quality &&= @quality.to_i
			end

			def data
					format = @format
					quality = @quality
					@image.to_blob do
						self.format = format
						self.quality = quality if quality
					end
			end

			def mime_type
				#@image.mime_type cannot be used since it is raw crated image
				#TODO: how do I do it better?
				mime = case @format
					when 'JPG' then 'jpeg'
					else @format.downcase
				end
				"image/#{mime}"
			end

			private

			def default_quality(format)
				case format
				when /png/i
					95 # max zlib compression, adaptive filtering (photo)
				when /jpeg|jpg/i
					85
				else
					nil
				end
			end
		end

		class Service
			include ClassLogging

			extend Stats
			def_stats(
				:total_images_loaded, 
				:total_images_prescaled, 
				:total_thumbnails_created, 
				:images_loaded, 
				:max_images_loaded, 
				:total_images_created,
				:total_images_destroyed,
				:total_images_created_from_blob,
				:total_images_created_initialize,
				:total_images_created_resize,
				:total_images_created_crop,
				:total_images_created_sample
			)

			def initialize(options = {})
				@processing_methods = {}
				@options = options

				log.info "initializing thumbniler"

				set_limit(:area, options[:limit_area]) if options.member?(:limit_area)
				set_limit(:memory, options[:limit_memory]) if options.member?(:limit_memory)
				set_limit(:map, options[:limit_map]) if options.member?(:limit_map)
				set_limit(:disk, options[:limit_disk]) if options.member?(:limit_disk)

				Magick.trace_proc = lambda do |which, description, id, method|
					case which
					when :c
						Service.stats.incr_images_loaded
						Service.stats.max_images_loaded = Service.stats.images_loaded if Service.stats.images_loaded > Service.stats.max_images_loaded
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
						else
							log.warn "uncounted image creation method: #{method}"
						end
					when :d
						Service.stats.decr_images_loaded
						Service.stats.incr_total_images_destroyed
					end
					log.debug{"image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{Service.stats.images_loaded}"}
				end
			end

			def load(io, options = {})
				mw = options['max-width']
				mh = options['max-height']
				if mw and mh
					mw = mw.to_i
					mh = mh.to_i
					log.info "using max size hint of: #{mw}x#{mh}"
				end

				begin
					blob = io.read
					images = Magick::Image.from_blob(blob) do |info|
						if mw and mh
							define('jpeg', 'size', "#{mw*2}x#{mh*2}")
							define('jbig', 'size', "#{mw*2}x#{mh*2}")
						end
					end

					image = images.first
					if image.columns > image.base_columns or image.rows > image.base_rows
						log.warn "input image got upscaled from: #{image.base_columns}x#{image.base_rows} to #{image.columns}x#{image.rows}: reloading without max size hint!"
						images.each do |other|
							other.destroy!
						end
						images = Magick::Image.from_blob(blob)
					end
					blob = nil

					images.shift.replace do |image|
						images.each do |other|
							other.destroy!
						end
						log.info "loaded image: #{image.inspect}"
						Service.stats.incr_total_images_loaded
						image.strip!
					end.replace do |image|
						if mw and mh
							f = image.find_prescale_factor(mw, mh)
							if f > 1
								image = image.prescale(f)
								log.info "prescaled image by factor of #{f}: #{image.inspect}"
								Service.stats.incr_total_images_prescaled
							end
						end
						InputImage.new(image, @processing_methods)
					end
				rescue Magick::ImageMagickError => error
					raise ImageTooLargeError, error if error.message =~ /cache resources exhausted/
					raise UnsupportedMediaTypeError, error
				end
			end

			def processing_method(method, &impl)
				@processing_methods[method] = impl
			end

			def set_limit(limit, value)
				old = Magick.limit_resource(limit, value)
				log.info "changed limit of #{limit} from #{old} to #{value}"
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

			@@service.processing_method('crop') do |image, width, height, options|
				image.resize_to_fill(width, height) if image.columns != width or image.rows != height
			end

			@@service.processing_method('fit') do |image, width, height, options|
				image.resize_to_fit(width, height) if image.columns != width or image.rows != height
			end

			@@service.processing_method('pad') do |image, width, height, options|
				image.resize_to_fit(width, height).replace do |resize|
					resize.render_on_background(options['background-color'], width, height)
				end if image.columns != width or image.rows != height
			end

			@@service.processing_method('limit') do |image, width, height, options|
				image.resize_to_fit(width, height) if image.columns > width or image.rows > height
			end
		end

		def thumbnailer
			@@service
		end
	end
end

class Magick::Image
	include Plugin::Thumbnailer::ImageProcessing

	def render_on_background(background_color, width = nil, height = nil)
		Magick::Image.new(width || self.columns, height || self.rows) {
			self.background_color = background_color
			self.depth = 8
		}.replace do |background|
			background.composite!(self, Magick::CenterGravity, Magick::OverCompositeOp)
		end
	end

	# non coping version
	def resize_to_fill(ncols, nrows = nil, gravity = Magick::CenterGravity)
		nrows ||= ncols
		if ncols != columns or nrows != rows
			scale = [ncols / columns.to_f, nrows / rows.to_f].max
			resize(scale * columns + 0.5, scale * rows + 0.5).replace do |image|
				image.crop(gravity, ncols, nrows, true) if ncols != columns or nrows != rows
			end
		else
			crop(gravity, ncols, nrows, true) if ncols != columns or nrows != rows
		end
	end

	def prescale(f)
		sample(columns / f, rows / f)
	end

	def find_prescale_factor(max_width, max_height, factor = 1)
		new_factor = factor * 2
		if columns / new_factor > max_width * 2 and rows / new_factor > max_height * 2
			find_prescale_factor(max_width, max_height, factor * 2)
		else
			factor
		end
	end
end

