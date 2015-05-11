thumbnailing_method('cut')  do |image, width, height, options|
	cut_x = Float(options['box-x']) rescue 0.25
	cut_y = Float(options['box-y']) rescue 0.25
	cut_w = Float(options['box-w']) rescue 0.5
	cut_h = Float(options['box-h']) rescue 0.5

	image.crop(cut_x * image.columns, cut_y * image.rows, cut_w * image.columns, cut_h * image.rows, true).replace do |image|
		image.resize_to_fit(width, height) if image.columns != width or image.rows != height
	end
end

