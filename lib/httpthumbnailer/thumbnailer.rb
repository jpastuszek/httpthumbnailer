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
				opts.merge!({'max-width' => spec.width, 'max-height' => spec.height})
			end

			thumbnailer.load(req.body, opts).use do |input_image|
				log.info "original image loaded: #{input_image.mime_type}"
				res["X-Input-Image-Content-Type"] = input_image.mime_type

				log.info "generating thumbnail: #{spec}"
				input_image.thumbnail(spec) do |image|
					res["Content-Type"] = image.mime_type
					res.status = 200
					res.write image.data
				end
			end
		end

		on put, 'thumbnails', /(.*)/ do |specs|
			thumbnail_specs = ThumbnailSpecs.from_uri(specs)
			log.info "thumbnailing image to multiple specs: #{thumbnail_specs.join(', ')}"

			opts = {}
			if settings[:optimization]
				opts.merge!({'max-width' => thumbnail_specs.max_width, 'max-height' => thumbnail_specs.max_height})
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
						log.error "thumbnailing error", error
						write_error_part error
					end
				end
				write_epilogue
			end
		end
	end
end

