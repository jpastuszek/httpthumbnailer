require 'logger'
require 'rmagick'

class Magick::Image
	def render_on_background!(background_color)
		Thumbnailer::ImageHandler.new do
			self
		end.use do |image|
			Magick::Image.new(image.columns, image.rows) {
				self.background_color = background_color
			}.composite!(image, Magick::CenterGravity, Magick::OverCompositeOp)
		end
	end
end

class Thumbnailer
	class UnsupportedMethodError < ArgumentError
		def initialize(method)
			super("Thumbnail method '#{method}' is not supported")
		end
	end

	class UnsupportedMediaTypeError < ArgumentError
		def initialize(e)
			super("#{e.class.name}: #{e}")
		end
	end

	class ImageTooLargeError < ArgumentError
		def initialize(e)
			super("#{e.class.name}: #{e}")
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
				@image.destroy!
				@image = nil
				raise
			end
		end

		def use
			raise ImageDestroyedError unless @image
			begin
				yield @image
			ensure
				@image.destroy!
				@image = nil
			end
		end

		def destroy!
			return unless @image
			@image.destroy!
			@image = nil
		end
	end

	class InputImage
		def initialize(io, methods, options = {})
			@options = options
			@logger = (options[:logger] or Logger.new('/dev/null'))

			mw = options['max-width']
			mh = options['max-height']
			if mw and mh
				mw = mw.to_i
				mh = mh.to_i
				@logger.info "Using max size hint of: #{mw}x#{mh}"
			end

			begin
				@image = Magick::Image.from_blob(io.read) do |info|
					if mw and mh
						define('jpeg', 'size', "#{mw*2}x#{mh*2}")
						define('jbig', 'size', "#{mw*2}x#{mh*2}")
					end
				end.first.strip!
				@logger.info "Loaded image: #{@image.inspect}"
				
				if mw and mh
					f = find_prescale_factor(mw, mh)
					if f > 1
						prescale(f)
						@logger.info "Prescaled image by factor of #{f}: #{@image.inspect}"
					end
				end
			rescue Magick::ImageMagickError => e
				raise ImageTooLargeError, e if e.message =~ /cache resources exhausted/
				raise UnsupportedMediaTypeError, e
			end

			@methods = methods
		end

		def prescale(f)
			@image.sample!(@image.columns / f, @image.rows / f)
		end

		def thumbnail(spec)
			begin
				ImageHandler.new do
					width = spec.width == :input ? @image.columns : spec.width
					height = spec.height == :input ? @image.rows : spec.height

					process_image(@image, spec.method, width, height, spec.options).render_on_background!((spec.options['background-color'] or 'white').sub(/^0x/, '#'))
				end.use do |image|
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
			copy = image.copy
			begin
				impl.call(copy, width, height, options)
			rescue
				copy.destroy!
				raise
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

	def initialize(options = {})
		@methods = {}
		@options = options
		@logger = (options[:logger] or Logger.new('/dev/null'))

		@logger.info "Initializing thumbniler"

		set_limit(:area, options[:limit_area]) if options.member?(:limit_area)
		set_limit(:memory, options[:limit_memory]) if options.member?(:limit_memory)
		set_limit(:map, options[:limit_map]) if options.member?(:limit_map)
		set_limit(:disk, options[:limit_disk]) if options.member?(:limit_disk)

		@images = 0
		Magick.trace_proc = lambda do |which, description, id, method|
			case which
			when :c
				@images += 1
			when :d
				@images -= 1
			end
			@logger.debug "Image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{images}"
		end
	end

	def load(io, options = {})
		ImageHandler.new do
			InputImage.new(io, @methods, @options.merge(options))
		end
	end

	def images
		@images
	end

	def method(method, &impl)
		@methods[method] = impl
	end

	def set_limit(limit, value)
		old = Magick.limit_resource(limit, value)
		@logger.info "Changed limit of #{limit} from #{old} to #{value}"
	end
end

