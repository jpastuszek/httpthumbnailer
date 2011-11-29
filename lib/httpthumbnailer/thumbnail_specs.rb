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
end

