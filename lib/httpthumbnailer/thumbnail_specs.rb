class ThumbnailSpecs < Array
	def self.from_uri(specs)
		ts = ThumbnailSpecs.new
		specs.split('/').each do |spec|
			ts << ThumbnailSpec.from_uri(spec)
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

class ThumbnailSpec
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

		class BadDimensionValueError < BadThubnailSpecError
			def initialize(value)
				super "bad dimension value: #{value}"
			end
		end
	end

	class Edit
		attr_reader :name, :args

		def initialize(name, *args)
			@name = name
			@args = args
		end

		def to_s
			"#{name}(#{args.join(',')})"
		end
	end

	def initialize(method, width, height, format, options = {}, edits = [])
		@method = method
		@width = cast_dimension(width)
		@height = cast_dimension(height)
		@format = (format == 'input' ? :input : format.upcase)
		@options = options
		@edits = edits
	end

	def self.from_uri(spec)
		spec, *edits = *spec.split('!')
		method, width, height, format, *options = *spec.split(',')
		raise BadThubnailSpecError::MissingArgumentError.new(spec) unless method and width and height and format

		opts = {}
		options.each do |option|
			key, value = option.split(':')
			raise BadThubnailSpecError::MissingOptionKeyOrValueError.new(option) unless key and value
			opts[key] = value
		end

		edits = edits.map do |edit|
			name, *args = *edit.split(',')
			args, *edit_options = *args.slice_before{|a| a =~ /.+:.+/}.to_a
			edit_options.flatten!

			edit_opts = {}
			edit_options.each do |option|
				key, value = option.split(':')
				raise BadThubnailSpecError::MissingOptionKeyOrValueError.new(option) unless key and value
				edit_opts[key] = value
			end

			args << edit_opts unless edit_opts.empty?
			Edit.new(name, *args)
		end

		ThumbnailSpec.new(method, width, height, format, opts, edits)
	end


	attr_reader :method, :width, :height, :format, :options, :edits

	def to_s
		"#{method} #{width}x#{height} (#{format.downcase}) #{options.inspect} [#{edits.join(' ')}]"
	end

	private

	def cast_dimension(string)
		return :input if string == 'input'
		raise BadThubnailSpecError::BadDimensionValueError.new(string) unless string =~ /^\d+$/
		string.to_i
	end
end

