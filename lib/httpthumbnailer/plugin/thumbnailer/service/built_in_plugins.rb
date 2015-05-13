module Plugin
	module Thumbnailer
		class Service
			def self.built_in_plugin
				PluginContext.new do
					thumbnailing_method('crop') do |image, width, height, options|
						image.resize_to_fill(width, height, float!('float-x', options['float-x'], 0.5), float!('float-y', options['float-y'], 0.5)) if image.width != width or image.height != height
					end

					thumbnailing_method('fit') do |image, width, height, options|
						image.resize_to_fit(width, height) if image.width != width or image.height != height
					end

					thumbnailing_method('pad') do |image, width, height, options|
						image.resize_to_fit(width, height).get do |resize|
							resize.render_on_background(options['background-color'], width, height, float!('float-x', options['float-x'], 0.5), float!('float-y', options['float-y'], 0.5))
						end if image.width != width or image.height != height
					end

					thumbnailing_method('limit') do |image, width, height, options|
						image.resize_to_fit(width, height) if image.width > width or image.height > height
					end

					edit('resize_crop') do |image, width, height, options, thumbnail_spec|
						width = float!('width', width)
						height = float!('height', height)

						image.resize_to_fill(width, height, ufloat!('float-x', options['float-x'], 0.5), ufloat!('float-y', options['float-y'], 0.5)) if image.width != width or image.height != height
					end

					edit('resize_fit') do |image, width, height, options, thumbnail_spec|
						width = float!('width', width)
						height = float!('height', height)

						image.resize_to_fit(width, height) if image.width != width or image.height != height
					end

					edit('resize_limit') do |image, width, height, options, thumbnail_spec|
						width = float!('width', width)
						height = float!('height', height)

						image.resize_to_fit(width, height) if image.width > width or image.height > height
					end

					edit('crop') do |image, x, y, width, height, options, thumbnail_spec|
						x = ufloat!('x', x)
						y = ufloat!('y', y)
						width = ufloat!('width', width)
						height = ufloat!('height', height)

						image.crop(
							*image.rel_to_px(x, y),
							*image.rel_to_px(width, height),
							true
						) if image.width != width or image.height != height
					end

					edit('pixelate') do |image, box_x, box_y, box_width, box_height, options, thumbnail_spec|
						box_x = ufloat!('box_x', box_x)
						box_y = ufloat!('box_y', box_y)
						box_width = ufloat!('box_width', box_width)
						box_height = ufloat!('box_height', box_height)

						size = ufloat!('size', options['size'], 0.01)

						# make size relative to image diagonal
						diag = Math.sqrt(image.width ** 2 + image.height ** 2)

						image.pixelate_region(
							*image.rel_to_px(box_x, box_y),
							*image.rel_to_px(box_width, box_height),
							size * diag
						)
					end

					edit('blur') do |image, box_x, box_y, box_width, box_height, options, thumbnail_spec|
						box_x = ufloat!('box_x', box_x)
						box_y = ufloat!('box_y', box_y)
						box_width = ufloat!('box_width', box_width)
						box_height = ufloat!('box_height', box_height)

						radius = uint!('radius', options['radius'], 0) # auto
						sigma = ufloat!('sigma', options['sigma'], 0.01)

						# make radius and sigma relative to image diagonal
						diag = Math.sqrt(image.width ** 2 + image.height ** 2)

						radius = radius * diag
						sigma = sigma * diag

						if radius > 50
							log.warn "limiting effective radius from #{radius} down to 50"
							radius = 50
						end

						if sigma > 50
							log.warn "limiting effective sigma from #{sigma} down to 50"
							sigma = 50
						end

						image.blur_region(
							*image.rel_to_px(box_x, box_y),
							*image.rel_to_px(box_width, box_height),
							radius, sigma
						)
					end

					edit('rotate') do |image, angle, options, thumbnail_spec|
						angle = float!('angle', angle)
						image.with_background_color(options['background-color'] || thumbnail_spec.options['background-color']) do
							image.rotate(angle)
						end
					end
				end
			end
		end
	end
end

