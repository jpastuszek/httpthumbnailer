require 'httpthumbnailer/plugin/thumbnailer'
require 'httpthumbnailer/thumbnail_specs'

class Thumbnailer < Controler
	self.plugin Plugin::Thumbnailer

	self.define do
		on put, 'thumbnail', /(.*)/ do |spec|
			spec = ThumbnailSpec.from_uri(spec)
			log.info "thumbnailing image to single spec: #{spec}"

			opts = {}
			if settings[:optimization]
				opts['max-width'] = spec.width if spec.width.is_a? Integer
				opts['max-height'] = spec.height if spec.height.is_a? Integer
			end

			thumbnailer.load(req.body, opts).use do |input_image|
				log.info "original image loaded: #{input_image.mime_type}"
				res["X-Input-Image-Content-Type"] = input_image.mime_type

				log.info "generating thumbnail: #{spec}"
				input_image.thumbnail(spec) do |image|
					write 200, image.mime_type, image.data
				end
			end
		end

		on put, 'thumbnails', /(.*)/ do |specs|
			thumbnail_specs = ThumbnailSpecs.from_uri(specs)
			log.info "thumbnailing image to multiple specs: #{thumbnail_specs.join(', ')}"

			opts = {}
			if settings[:optimization]
					opts['max-width'] = thumbnail_specs.max_width
					opts['max-height'] = thumbnail_specs.max_height
			end

			thumbnailer.load(req.body, opts).use do |input_image|
				log.info "original image loaded: #{input_image.mime_type}"
				write_preamble 200, "X-Input-Image-Content-Type" => input_image.mime_type

				thumbnail_specs.each do |spec|
					log.info "generating thumbnail: #{spec}"
					begin
						input_image.thumbnail(spec) do |image|
							write_part image.mime_type, image.data
						end
					rescue => error
						case error
						when Plugin::Thumbnailer::ImageTooLargeError
							write_error_part 413, error
						when Plugin::Thumbnailer::UnsupportedMethodError
							write_error_part 400, error
						when Plugin::Thumbnailer::ZeroSizedImageError
							write_error_part 400, error
						else
							log.error "unhandled error while generating multipart response for thumbnail spec: #{spec}", error
							write_error_part 500, error
						end
					end
				end
				write_epilogue
			end
		end
	end
end

