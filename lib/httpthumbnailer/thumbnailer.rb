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

	def load(id, io)
		@logger.info "Loading image #{id}"
		@images[id] = Magick::Image.from_blob(io.read).first
		@images[id].strip!

		return @images[id] unless block_given?
		begin
			yield @images[id]
			@logger.info "Done with image #{id}"
		ensure
			@logger.info "Destroying image #{id}"
			@images[id].destroy!
			@images.delete(id)
		end
	end

	def method(method, &impl)
		@methods[method] = impl
	end

	def thumbnail(id, spec)
		image = @images[id] or raise ImageNotFound.new(id)
		process_image(image, spec)
	end

	def process_image(image, spec)
		impl = @methods[spec.method] or raise UnsupportedMethodError.new(spec.method)
		impl.call(image, spec)
	end
end

