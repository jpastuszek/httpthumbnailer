require 'logger'

class ThumbnailSpec
	def initialize(method, width, height, format, options = {})
		@method = method
		@width = width
		@height = height
		@format = format.upcase
		@options = options
	end

	def mime
		mime = case format
			when 'JPG' then 'jpeg'
			else format.downcase
		end
		"image/#{mime}"
	end

	attr_reader :method, :width, :height, :format, :options

	def to_s
		"#{method} #{width}x#{height} #{mime} (#{format}) #{options.inspect}"
	end
end

class Thumbnailer
	class UnsupportedMethodError < ArgumentError
		def initialize(method)
			super("Thumbnail method '#{method}' is not supported")
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

		def use
			raise ImageDestroyedError unless @image
			begin
				yield @image
			ensure
				@image.destroy!
				@image = nil
			end
		end
	end

	class OriginalImage
		def initialize(io, methods, options = {})
			@options = options
			@logger = (options[:logger] or Logger.new('/dev/null'))

			@logger.info "Loading original image"
			@image = Magick::Image.from_blob(io.read).first.strip!
			@methods = methods
		end

		def thumbnail(spec)
			thumb = process_image(@image, spec)
			replace_transparency(thumb, spec)
		end

		def destroy!
			@logger.info "Destroing original image"
			@image.destroy!
		end

		private

		def replace_transparency(image, spec)
			Magick::Image.new(image.columns, image.rows) {
				self.background_color = (spec.options['background-color'] or 'white').sub(/^0x/, '#')
			}.composite!(image, Magick::CenterGravity, Magick::OverCompositeOp)
		end

		def process_image(image, spec)
			impl = @methods[spec.method] or raise UnsupportedMethodError.new(spec.method)
			impl.call(image, spec)
		end
	end

	def initialize(options = {})
		@methods = {}
		@options = options
		@logger = (options[:logger] or Logger.new('/dev/null'))

		@logger.info "Initializing thumbniler"

		@loaded_images = 0
		Magick.trace_proc = lambda do |which, description, id, method|
			case which
			when :c
				@loaded_images += 1
			when :d
				@loaded_images -= 1
			end
			@logger.info "Image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{loaded_images}"
		end
	end

	def load(io)
		ImageHandler.new do
			OriginalImage.new(io, @methods, @options)
		end
	end

	def loaded_images
		@loaded_images
	end

	def method(method, &impl)
		@methods[method] = impl
	end
end

