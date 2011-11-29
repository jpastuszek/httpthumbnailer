Given /httpthumbnailer server is running at (.*)/ do |url|
	start_server(
		"bundle exec #{script('httpthumbnailer')}",
		'/tmp/httpthumbnailer.pid',
		support_dir + 'server.log',
		url
	)
end

Given /(.*) file content as request body/ do |file|
	@request_body = File.open(support_dir + file){|f| f.read }
end

When /I do (.*) request (.*)/ do |method, url|
	@response = HTTPClient.new.request(method, url, nil, @request_body)
end

Then /I will get multipart response/ do
	@response.header['Content-Type'].first.should match /^multipart/
	@response_multipart = MultipartResponse.new(@response.header['Content-Type'].last, @response.body)
end

Then /(.*) part mime type will be (.*)/ do |part, mime|
	@response_multipart.part[part_no(part)].header['Content-Type'].should == mime
end

Then /(.*) part will contain (.*) image of size (.*)x(.*)/ do |part, format, width, height|
	mime = @response_multipart.part[part_no(part)].header['Content-Type']
	data = @response_multipart.part[part_no(part)].body
	fail("expecte image got #{mime}: #{data}") unless mime =~ /^image\//

	@image.destroy! if @image
	@image = Magick::Image.from_blob(data).first

	@image.format.should == format
	@image.columns.should == width.to_i
	@image.rows.should == height.to_i
end

And /(.*) part body will be saved as (.*) for human inspection/ do |part, file|
	data = @response_multipart.part[part_no(part)].body
	(support_dir + file).open('w'){|f| f.write(data)}
end

And /that image pixel at (.*)x(.*) will be of color (.*)/ do |x, y, color|
	@image.pixel_color(x.to_i, y.to_i).to_color.sub(/^#/, '0x').should == color
end


And /there will not be leaked images/ do
	HTTPClient.new.get_content("http://localhost:3100/stats/images/loaded").to_i.should == 0
end

