require 'RMagick'
require 'raindrops'

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

		module ImageProcessing
			def replace
				@use_count ||= 0
				processed = nil
				begin
					processed = yield self
					processed = self unless processed
					fail 'got destroyed image' if processed.destroyed?
				ensure
					self.destroy! if @use_count <= 0 if self != processed
				end
				processed
			end

			def use
				lock do |image|
					yield image
					image
				end
			end

			private

			def lock
				@use_count ||= 0
				@use_count += 1
				begin
					yield self
				ensure
					@use_count -=1
					self.destroy! if @use_count <= 0
				end
			end
		end

		module InputImage
			include ImageProcessing

			def processing_methods=(processing_methods)
				@processing_methods = processing_methods
			end

			def stats=(stats)
				@stats = stats
			end

			def logger=(logger)
				@logger = logger
			end

			def thumbnail(spec)
				spec = spec.dup
				# default backgraud is white
				spec.options['background-color'] = spec.options.fetch('background-color', 'white').sub(/^0x/, '#')

				width = spec.width == :input ? columns : spec.width
				height = spec.height == :input ? rows : spec.height

				begin
					process_image(spec.method, width, height, spec.options).replace do |image|
						if image.alpha?
							@logger.info 'thumbnail has alpha, rendering on background'
							image.render_on_background(spec.options['background-color'])
						end
					end.use do |image|
						@stats.incr_total_thumbnails_created
						image_format = spec.format == :input ? format : spec.format

						yield Thumbnail.new(image, image_format, spec.options)
					end
				rescue Magick::ImageMagickError => error
					# Magick::Image overwrites raise (sic!)
					Kernel.raise ImageTooLargeError, error.message if error.message =~ /cache resources exhausted/
					Kernel.raise
				end
			end

			def process_image(method, width, height, options)
				replace do |image|
					impl = @processing_methods[method] or raise UnsupportedMethodError, method
					impl.call(image, width, height, options)
				end
			end
		end

		class Thumbnail
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
				#@image.mime_type cannot be used since it is raw loaded image
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
			class Stats < Raindrops::Struct.new(
					:total_images_loaded, 
					:total_images_prescaled, 
					:total_thumbnails_created, 
					:images_loaded, 
					:total_images_created,
					:total_images_destroyed,
					:total_images_created_from_blob,
					:total_images_created_initialize_copy,
					:total_images_created_initialize,
					:total_images_created_resize,
					:total_images_created_crop,
					:total_images_created_sample
				)
			end

			def initialize(options = {})
				@processing_methods = {}
				@options = options
				@logger = (options[:logger] or Logger.new('/dev/null'))
				@stats = Stats.new

				@logger.info "initializing thumbniler"

				set_limit(:area, options[:limit_area]) if options.member?(:limit_area)
				set_limit(:memory, options[:limit_memory]) if options.member?(:limit_memory)
				set_limit(:map, options[:limit_map]) if options.member?(:limit_map)
				set_limit(:disk, options[:limit_disk]) if options.member?(:limit_disk)

				Magick.trace_proc = lambda do |which, description, id, method|
					case which
					when :c
						@stats.incr_images_loaded
						@stats.incr_total_images_created
						case method
						when :from_blob
							@stats.incr_total_images_created_from_blob
						when :initialize_copy
							@stats.incr_total_images_created_initialize_copy
						when :initialize
							@stats.incr_total_images_created_initialize
						when :resize
							@stats.incr_total_images_created_resize
						when :resize!
							@stats.incr_total_images_created_resize
						when :crop
							@stats.incr_total_images_created_crop
						when :crop!
							@stats.incr_total_images_created_crop
						when :sample
							@stats.incr_total_images_created_sample
						else
							@logger.warn "uncounted image creation method: #{method}"
						end
					when :d
						@stats.decr_images_loaded
						@stats.incr_total_images_destroyed
					end
					@logger.debug "image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{@stats.images_loaded}"
				end
			end

			def load(io, options = {})
				mw = options['max-width']
				mh = options['max-height']
				if mw and mh
					mw = mw.to_i
					mh = mh.to_i
					@logger.info "using max size hint of: #{mw}x#{mh}"
				end

				begin
					images = Magick::Image.from_blob(io.read) do |info|
						if mw and mh
							define('jpeg', 'size', "#{mw*2}x#{mh*2}")
							define('jbig', 'size', "#{mw*2}x#{mh*2}")
						end
					end
					images.shift.replace do |image|
						images.each do |other|
							other.destroy!
						end
						@logger.info "loaded image: #{image.inspect}"
						@stats.incr_total_images_loaded
						image.strip!
					end.replace do |image|
						if mw and mh
							f = image.find_prescale_factor(mw, mh)
							if f > 1
								image = image.prescale(f)
								@logger.info "prescaled image by factor of #{f}: #{image.inspect}"
								@stats.incr_total_images_prescaled
							end
						end
						image.extend InputImage
						image.processing_methods = @processing_methods
						image.stats = @stats
						image.logger = @logger
						image
					end
				rescue Magick::ImageMagickError => error
					raise ImageTooLargeError, error if error.message =~ /cache resources exhausted/
					raise UnsupportedMediaTypeError, error
				end
			end

			def stats
				@stats
			end

			def method(method, &impl)
				@processing_methods[method] = impl
			end

			def set_limit(limit, value)
				old = Magick.limit_resource(limit, value)
				@logger.info "changed limit of #{limit} from #{old} to #{value}"
			end
		end

		def self.setup(app)
			@@service = Service.new(
				limit_memory: app.settings[:limit_memory],
				limit_map: app.settings[:limit_map],
				limit_disk: app.settings[:limit_disk],
				logger: app.logger_for(Service)
			)

			@@service.method('crop') do |image, width, height, options|
				image.resize_to_fill(width, height)
			end

			@@service.method('fit') do |image, width, height, options|
				image.resize_to_fit(width, height)
			end

			@@service.method('pad') do |image, width, height, options|
				image.resize_to_fit(width, height).replace do |resize|
					resize.render_on_background(options['background-color'], width, height)
				end
			end

			app.stats = @@service.stats
		end

		module ClassMethods
			def stats=(stats)
				@@stats = stats
			end

			def stats
				@@stats
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
		if ncols != columns || nrows != rows
			scale = [ncols/columns.to_f, nrows/rows.to_f].max
			resize(scale*columns+0.5, scale*rows+0.5).replace do |image|
				image.crop(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
			end
		else
			crop(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
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

