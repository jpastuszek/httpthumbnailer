require 'httpthumbnailer/thumbnailer'

class ThumbnailSpecs < Array
	class BadThubnailSpecFormat < ArgumentError
	end

	def self.from_uri(specs)
		ts = ThumbnailSpecs.new
		specs.split('/').each do |spec|
			method, width, height, format, *options = *spec.split(',')
			raise BadThubnailSpecFormat, "missing argument in: #{spec}" unless method and width and height and format

			width = width.to_i
			height = height.to_i

			opts = {}
			options.each do |option|
				key, value = option.split(':')
				raise BadThubnailSpecFormat, "missing option key or value in: #{option}" unless key and value
				opts[key] = value
			end

			ts << ThumbnailSpec.new(method, width, height, format, opts)
		end
		ts
	end

	def max_width
		map{|spec| spec.width}.max
	end

	def max_height
		map{|spec| spec.height}.max
	end

	def biggest_spec
		max_field = -1
		max_spec = nil
		each do |spec|
			field = spec.width * spec.height
			if max_field < field
				max_field = field
				max_spec = spec
			end
		end

		max_spec
	end
end

