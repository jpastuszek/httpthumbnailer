require 'RMagick'
require 'httpthumbnailer/thumbnailer'

class Magick::Image
	def render_on_background!(background_color, width = nil, height = nil)
		Plugin::Thumbnailer::ImageHandler.new do
			self
		end.use do |image|
			Plugin::Thumbnailer::ImageHandler.new do
				Magick::Image.new(width || image.columns, height || image.rows) {
					self.background_color = background_color
					self.depth = 8
				}
			end.get do |background|
				return background.composite!(image, Magick::CenterGravity, Magick::OverCompositeOp)
			end
		end
	end

	# non coping version
	def resize_to_fill(ncols, nrows = nil, gravity = Magick::CenterGravity)
		nrows ||= ncols
		if ncols != columns || nrows != rows
			scale = [ncols/columns.to_f, nrows/rows.to_f].max
			Plugin::Thumbnailer::ImageHandler.new do
				resize(scale*columns+0.5, scale*rows+0.5)
			end.get do |image|
				return image.crop!(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
				return image
			end
		else
			return crop(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
			# nothing to do make sure we return copy
			return copy
		end
	end
end

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

		class ImageHandler
			class ImageDestroyedError < RuntimeError
				def initialize
					super("image was already used")
				end
			end

			def initialize
				@image = yield
			end

			def get
				raise ImageDestroyedError unless @image
				begin
					yield @image
				rescue
					destroy!
					raise
				end
			end

			def use
				raise ImageDestroyedError unless @image
				begin
					yield @image
				ensure
					destroy!
				end
			end

			def destroy!
				return unless @image
				@image.destroy!
				@image = nil
			end
		end

		class InputImage
			def initialize(io, methods, stats, options = {})
				@stats = stats
				@options = options
				@logger = (options[:logger] or Logger.new('/dev/null'))

				mw = options['max-width']
				mh = options['max-height']
				if mw and mh
					mw = mw.to_i
					mh = mh.to_i
					@logger.info "using max size hint of: #{mw}x#{mh}"
				end

				begin
					@image = Magick::Image.from_blob(io.read) do |info|
						if mw and mh
							define('jpeg', 'size', "#{mw*2}x#{mh*2}")
							define('jbig', 'size', "#{mw*2}x#{mh*2}")
						end
					end.first.strip!
					@logger.info "loaded image: #{@image.inspect}"
					@stats.incr_total_images_loaded
					
					if mw and mh
						f = find_prescale_factor(mw, mh)
						if f > 1
							prescale(f)
							@logger.info "prescaled image by factor of #{f}: #{@image.inspect}"
							@stats.incr_total_images_prescaled
						end
					end
				rescue Magick::ImageMagickError => e
					raise ImageTooLargeError, e if e.message =~ /cache resources exhausted/
					raise UnsupportedMediaTypeError, e
				end

				@methods = methods
			end

			def thumbnail(spec)
				spec = spec.dup
				# default backgraud is white
				spec.options['background-color'] = spec.options.fetch('background-color', 'white').sub(/^0x/, '#')

				begin
					ImageHandler.new do
						width = spec.width == :input ? @image.columns : spec.width
						height = spec.height == :input ? @image.rows : spec.height

						image = process_image(@image, spec.method, width, height, spec.options)
						if image.alpha?
							@logger.info 'image has alpha, rendering on background'
							next image.render_on_background!(spec.options['background-color'])
						end
						image
					end.use do |image|
						@stats.incr_total_thumbnails_created
						format = spec.format == :input ? @image.format : spec.format

						yield Thumbnail.new(image, format, spec.options)
					end
				rescue Magick::ImageMagickError => e
					raise ImageTooLargeError, e if e.message =~ /cache resources exhausted/
					raise
				end
			end

			def mime_type
				@image.mime_type
			end

			def destroy!
				@image.destroy!
			end

			private

			def prescale(f)
				@image.sample!(@image.columns / f, @image.rows / f)
			end

			def find_prescale_factor(max_width, max_height, factor = 1)
				new_factor = factor * 2
				if @image.columns / new_factor > max_width * 2 and @image.rows / new_factor > max_height * 2
					find_prescale_factor(max_width, max_height, factor * 2)
				else
					factor
				end
			end

			def process_image(image, method, width, height, options)
				impl = @methods[method] or raise UnsupportedMethodError.new(method)
				# expecting original image not modified or destroyed
				impl.call(image, width, height, options)
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
				@methods = {}
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
						when :crop!
							@stats.incr_total_images_created_crop
						when :sample!
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
				ImageHandler.new do
					InputImage.new(io, @methods, @stats, @options.merge(options))
				end
			end

			def stats
				@stats
			end

			def method(method, &impl)
				@methods[method] = impl
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

			# first operation needs to be coping (no !) so we don't destroy original image
			@@service.method('crop') do |image, width, height, options|
				image.resize_to_fill(width, height)
			end

			@@service.method('fit') do |image, width, height, options|
				image.resize_to_fit(width, height)
			end

			@@service.method('pad') do |image, width, height, options|
				image
				.resize_to_fit(width, height)
				.render_on_background!(options['background-color'], width, height)
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

