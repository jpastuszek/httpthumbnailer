require 'httpthumbnailer/plugin/thumbnailer'
require 'httpthumbnailer/thumbnail_specs'

class Thumbnailer < Controller
	Plugin::Thumbnailer.logger = logger_for(Plugin::Thumbnailer)
	self.plugin Plugin::Thumbnailer

	self.define do
		opts = {}
		opts[:limit_memory] = memory_limit

		on put, 'thumbnail', /(.*)/ do |spec|
			spec = ThumbnailSpec.from_uri(spec)
			log.info "thumbnailing image to single spec: #{spec}"

			if settings[:optimization]
				opts[:max_width] = spec.width if spec.width.is_a? Integer
				opts[:max_height] = spec.height if spec.height.is_a? Integer
			end

			thumbnailer.load(req.body, opts) do |input_image|
				log.info "original image loaded: #{input_image.mime_type}"

				log.info "generating thumbnail: #{spec}"
				input_image.thumbnail(spec) do |image|
					write 200, image.mime_type, image.data,
						"X-Image-Width" => image.width,
						"X-Image-Height" => image.height,
						"X-Input-Image-Mime-Type" => input_image.mime_type,
						"X-Input-Image-Width" => input_image.width,
						"X-Input-Image-Height" => input_image.height
				end
			end
		end

		on put, 'thumbnails', /(.*)/ do |specs|
			thumbnail_specs = ThumbnailSpecs.from_uri(specs)
			log.info "thumbnailing image to multiple specs: #{thumbnail_specs.join(', ')}"

			if settings[:optimization]
					opts[:max_width] = thumbnail_specs.max_width
					opts[:max_height] = thumbnail_specs.max_height
			end

			thumbnailer.load(req.body, opts) do |input_image|
				log.info "original image loaded: #{input_image.mime_type}"
				write_preamble 200,
					"X-Input-Image-Mime-Type" => input_image.mime_type,
					"X-Input-Image-Width" => input_image.width,
					"X-Input-Image-Height" => input_image.height

				thumbnail_specs.each do |spec|
					log.info "generating thumbnail: #{spec}"
					begin
						input_image.thumbnail(spec) do |image|
							write_part image.mime_type, image.data,
								"X-Image-Width" => image.width,
								"X-Image-Height" => image.height
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

		on put, 'identify' do
			log.info "identifying image"
			# load as little of image as possible
			if settings[:optimization]
					opts[:max_width] = 2
					opts[:max_height] = 2
			end

			# disable preprocessing since we don't need them here
			opts[:no_reload] = true
			opts[:no_downscale] = true

			# RMagick of v2.13.2 does not use ImageMagick's PingBlob so we have to actually load the image
			thumbnailer.load(req.body, opts) do |input_image|
				mime_type = input_image.mime_type
				log.info "image loaded and identified as: #{mime_type}"
				write_json 200, {
					'mimeType' => mime_type,
					'width' => input_image.width,
					'height' => input_image.height
				}
			end
		end
	end
end

