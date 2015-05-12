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

					edit('cut') do |image, x, y, width, height, options, thumbnail_spec|
						x = float!('x', x)
						y = float!('y', y)
						width = float!('width', width)
						height = float!('height', height)

						image.crop(
							*image.rel_to_px(x, y),
							*image.rel_to_px(width, height),
							true
						) if image.width != width or image.height != height
					end

					edit('blur') do |image, box_x, box_y, box_width, box_height, options, thumbnail_spec|
						box_x = float!('box_x', box_x)
						box_y = float!('box_y', box_y)
						box_width = float!('box_width', box_width)
						box_height = float!('box_height', box_height)

						radious = float!('radious', options['radious'], 0.0) # auto
						sigma = float!('sigma', options['sigma'], 20)

						image.blur_region(
							*image.rel_to_px(box_x, box_y),
							*image.rel_to_px(box_width, box_height),
							radious, sigma
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

