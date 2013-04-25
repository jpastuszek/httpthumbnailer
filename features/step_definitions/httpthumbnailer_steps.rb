Given /httpthumbnailer log is empty/ do
		(support_dir + 'server.log').truncate(0)
end

Given /httpthumbnailer server is running at (.*)/ do |url|
	log = support_dir + 'server.log'
	cmd = "bundle exec #{script('httpthumbnailer')} -f -v -d -l #{log}"
	start_server(cmd, '/tmp/httpthumbnailer.pid', log, url)
end

Given /(.*) file content as request body/ do |file|
	@request_body = File.open(support_dir + file){|f| f.read }
end

When /I do (.*) request (.*)/ do |method, url|
	@response = HTTPClient.new.request(method, url, nil, @request_body)
end

Then /(.*) header will be (.*)/ do |header, value|
	@response.header[header].should_not be_empty
	@response.header[header].first.should == value
end

Then /I will get multipart response/ do
	@response.header['Content-Type'].first.should match /^multipart/
	@response_multipart = MultipartResponse.new(@response.header['Content-Type'].last, @response.body)
end

Then /response body will be CRLF endend lines like/ do |body|	
	@response.body.should match(body)
	@response.body.each_line do |line|
		line[-2,2].should == "\r\n"
	end
end

Then /response body will be CRLF endend lines$/ do |body|	
	@response.body.should == body.gsub("\n", "\r\n") + "\r\n"
end

Then /response status will be (.*)/ do |status|
	@response.status.should == status.to_i
end

Then /response content type will be (.*)/ do |content_type|
	@response.header['Content-Type'].first.should == content_type
end

Then /(.*) part mime type will be (.*)/ do |part, mime|
	@response_multipart.part[part_no(part)].header['Content-Type'].should == mime
end

Then /(.*) part content type will be (.*)/ do |part, content_type|
	@response_multipart.part[part_no(part)].header['Content-Type'].should == content_type
end

Then /(.*) part body will be CRLF endend lines$/ do |part, body|	
	@response_multipart.part[part_no(part)].body.should == body.gsub("\n", "\r\n")
end

Then /(.*) part body will be CRLF endend lines like$/ do |part, body|	
	pbody = @response_multipart.part[part_no(part)].body
	pbody.should match(body)
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

Then /(.*) part will contain body of size within (.*) of (.*)/ do |part, margin, size|
	data = @response_multipart.part[part_no(part)].body
	data.length.should be_within(margin.to_i).of(size.to_i)
end

Then /(.*) part will contain body smaller than (.*) part/ do |part, big_part|
	data = @response_multipart.part[part_no(part)].body
	data_big = @response_multipart.part[part_no(big_part)].body
	data.length.should < data_big.length
end

And /(.*) part body will be saved as (.*) for human inspection/ do |part, file|
	data = @response_multipart.part[part_no(part)].body
	(support_dir + file).open('w'){|f| f.write(data)}
end

And /that image pixel at (.*)x(.*) will be of color (.*)/ do |x, y, color|
	@image.pixel_color(x.to_i, y.to_i).to_color.sub(/^#/, '0x').should == color
end

And /there will be no leaked images/ do
	HTTPClient.new.get_content("http://localhost:3100/stats/images").to_i.should == 0
end

