require 'logger'

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

			@image = Magick::Image.from_blob(io.read).first.strip!
			@methods = methods
		end

		def thumbnail(spec)
			ImageHandler.new do
				process_image(@image, spec).render_on_background!((spec.options['background-color'] or 'white').sub(/^0x/, '#'))
			end.use do |thumb|
				thumb.to_blob do |inf|
					inf.format = spec.format
				end
			end
		end

		def destroy!
			@image.destroy!
		end

		private

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

	def load(io)
		ImageHandler.new do
			OriginalImage.new(io, @methods, @options)
		end
	end

	def images
		@images
	end

	def method(method, &impl)
		@methods[method] = impl
	end
end

