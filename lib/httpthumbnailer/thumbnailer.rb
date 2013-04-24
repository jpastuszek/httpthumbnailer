require 'httpthumbnailer/plugin/thumbnailer'
require 'httpthumbnailer/thumbnail_specs'

class Thumbnailer < Controler
	self.plugin Plugin::Thumbnailer

	self.define do
		on 'stats' do
			on 'images' do
				res.write thumbnailer.images.to_s
			end
		end

		on put, 'thumbnail', /(.*)/ do |specs|
			thumbnail_specs = ThumbnailSpecs.from_uri(specs)
			log.info "thumbnailing image to: #{thumbnail_specs.join(', ')}"

			opts = {}
			if settings[:optimization]
				opts.merge!({'max-width' => thumbnail_specs.max_width, 'max-height' => thumbnail_specs.max_height})
			end

			input_image_handler = thumbnailer.load(req.body, opts)

			input_image_handler.get do |input_image|
				log.debug "original image loaded"

				res.status = 200
				res["Content-Type"] = "multipart/mixed; boundary=\"#{settings[:boundary]}\""
				res["X-Input-Image-Content-Type"] = input_image.mime_type

				input_image_handler.use do |input_image|
					thumbnail_specs.each do |spec|
						log.info "generating thumbnail: #{spec}"
						res.write "--#{settings[:boundary]}\r\n"

						begin
							input_image.thumbnail(spec) do |thumbnail|
								res.write "Content-Type: #{thumbnail.mime_type}\r\n\r\n"
								res.write thumbnail.data
							end
						rescue => e
							log.error "thumbnailing error: #{e.class.name}: #{e}: \n#{e.backtrace.join("\n")}"
							res.write "Content-Type: text/plain\r\n\r\n"
							res.write "Error: #{e}\r\n"
						ensure
							res.write "\r\n"
						end
					end
					res.write "--#{settings[:boundary]}--"
				end
			end
		end
	end
end

