thumbnailing_method('blur')  do |image, width, height, options|
	radius = Float(options['radius']) rescue 0.0 # auto
	sigma = Float(options['sigma']) rescue 2.5

	box_x = Float(options['box-x']) rescue 0.25
	box_y = Float(options['box-y']) rescue 0.25
	box_w = Float(options['box-w']) rescue 0.5
	box_h = Float(options['box-h']) rescue 0.5

	image.blur_region(
		*image.rel_to_px_box(box_x, box_y, box_w, box_h),
		radius, sigma
	).get do |image|
		image.resize_to_fit(width, height) if image.columns != width or image.rows != height
	end
end

