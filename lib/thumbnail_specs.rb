require 'thumbnailer'

class ThumbnailSpecs < Array
	def self.from_uri(specs)
		ts = ThumbnailSpecs.new
		specs.split('/').each do |spec|
			method, width, height, format, *options = *spec.split(',')
			width = width.to_i
			height = height.to_i

			opts = {}
			options.each do |option|
				key, value = option.split(':')
				opts[key] = value
			end

			ts << ThumbnailSpec.new(method, width, height, format, opts)
		end
		ts
	end
end

