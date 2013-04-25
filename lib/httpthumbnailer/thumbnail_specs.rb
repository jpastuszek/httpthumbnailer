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

		class BadDimmensionValueError < BadThubnailSpecError
			def initialize(value)
				super "bad dimmension value: #{value}"
			end
		end
	end

	class ThumbnailSpec
		def initialize(method, width, height, format, options = {})
			@method = method
			@width = cast_dimmension(width)
			@height = cast_dimmension(height)
			@format = (format == 'INPUT' ? :input : format.upcase)
			@options = options
		end

		attr_reader :method, :width, :height, :format, :options

		def to_s
			"#{method} #{width}x#{height} (#{format}) #{options.inspect}"
		end

		private

		def cast_dimmension(string)
			return :input if string == 'INPUT'
			raise BadThubnailSpecError::BadDimmensionValueError.new(string) unless string =~ /^\d+$/
			string.to_i
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
			return nil unless spec.width.is_a? Integer
			spec.width
		end.max
	end

	def max_height
		map do |spec|
			return nil unless spec.height.is_a? Integer
			spec.height
		end.max
	end
end

