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

	class OriginalImage
		def initialize(io, methods, options = {})
			@options = options
			@logger = (options[:logger] or Logger.new('/dev/null'))

			begin
				@image = Magick::Image.from_blob(io.read).first.strip!
			rescue Magick::ImageMagickError => e
				raise ImageTooLargeError, e if e.message =~ /cache resources exhausted/
				raise UnsupportedMediaTypeError, e
			end
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
			copy = image.copy
			begin
				impl.call(copy, spec)
			rescue
				copy.destroy!
				raise
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

	def load(io)
		h = ImageHandler.new do
			OriginalImage.new(io, @methods, @options)
		end

		begin
			yield h
		rescue
			# make sure that we destroy original image if there was an error before it could be used
			h.destroy!
			raise
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

