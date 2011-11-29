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

	class ImageNotFound < ArgumentError
		def initialize(id)
			super("No image of ID '#{id}' found")
		end
	end

	def initialize(options = {})
		@images = {}
		@methods = {}
		@options = options
		@options = options
		@logger = (options[:logger] or Logger.new('/dev/null'))
	end

	def load(io)
		@logger.info "Loading image"
		@image = Magick::Image.from_blob(io.read).first.strip!
	end

	def method(method, &impl)
		@methods[method] = impl
	end

	def thumbnail(image, spec)
		thumb = process_image(image, spec)
		replace_transparency(thumb, spec)
	end

	def replace_transparency(image, spec)
		Magick::Image.new(image.columns, image.rows) {
			self.background_color = (spec.options['background-color'] or 'white').sub(/^0x/, '#')
		}.composite!(image, Magick::CenterGravity, Magick::OverCompositeOp)
	end

	def process_image(image, spec)
		impl = @methods[spec.method] or raise UnsupportedMethodError.new(spec.method)
		impl.call(image, spec)
	end

	private

	def image(method)
		begin
			img = method.call
			yield img
		ensure
			img.destroy!
			img = nil
		end
	end
end

