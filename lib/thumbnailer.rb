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

	def initialize
		@images = {}
		@methods = {}
	end

	def load(id, io)
		puts "Loading image #{id}"
		@images[id] = Magick::Image.from_blob(io.read).first
		@images[id].strip!

		return @images[id] unless block_given?
		begin
			yield @images[id]
			puts "Done with image #{id}"
		rescue => e
			puts "Got error #{e}"
			raise
		ensure
			puts "Destroying image #{id}"
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

