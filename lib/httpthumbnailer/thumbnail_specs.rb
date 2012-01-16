require 'httpthumbnailer/thumbnailer'

class ThumbnailSpecs < Array
	class BadThubnailSpecError < ArgumentError
		class MissingArgumentError < BadThubnailSpecError
			def initialize(spec)
				super "missing argument in: #{spec}"
			end
		end

		class MissingOptionKeyOrValueError < BadThubnailSpecError
			def initialize(option)
				super "missing option key or value in: #{option}"
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

		attr_reader :method, :width, :height, :format, :options

		def to_s
			"#{method} #{width}x#{height} (#{format}) #{options.inspect}"
		end
	end

	def self.from_uri(specs)
		ts = ThumbnailSpecs.new
		specs.split('/').each do |spec|
			method, width, height, format, *options = *spec.split(',')
			raise BadThubnailSpecError::MissingArgumentError.new(spec) unless method and width and height and format

			opts = {}
			options.each do |option|
				key, value = option.split(':')
				raise BadThubnailSpecError::MissingOptionKeyOrValueError.new(option) unless key and value
				opts[key] = value
			end

			ts << ThumbnailSpec.new(method, width, height, format, opts)
		end
		ts
	end

	def max_width
		map do |spec|
			return nil if spec.width == 'INPUT'
			spec.width.to_i
		end.max
	end

	def max_height
		map do |spec|
			return nil if spec.height == 'INPUT'
			spec.height.to_i
		end.max
	end
end

