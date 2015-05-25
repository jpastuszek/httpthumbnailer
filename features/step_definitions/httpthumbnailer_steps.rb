Given /httpthumbnailer plugins dir (.*)/ do |plugins|
	@args ||= []
	@args << ['--plugins', plugins]
end

Given /httpthumbnailer server is running at (.*)/ do |url|
	@args ||= []
	log = support_dir + 'server.log'
	cmd = "bundle exec #{script('httpthumbnailer')} -f -d -l '#{log}' -w 1 #{@args.join(' ')}"
	start_server(cmd, '/tmp/httpthumbnailer.pid', log, url)
end

Given /(.*) file content as request body/ do |file|
	@request_body = File.open(support_dir + file){|f| f.read }
end

When /I do (.*) request (.*)/ do |method, url|
	@response = http_client.request(method, url, nil, @request_body)
end

When /I save response body/ do
	@saved_response_body = @response.body
end

Then /^([^ ]+) header should be (.*)/ do |header, value|
	@response.header[header].should_not be_empty
	@response.header[header].first.should == value
end

Then /I should get multipart response/ do
	@response.header['Content-Type'].first.should match /^multipart/
	parser = MultipartParser::Reader.new(MultipartParser::Reader.extract_boundary_value(@response.header['Content-Type'].last))
	@response_multipart = []

	parser.on_part do |part|
		part_struct = OpenStruct.new
		part_struct.headers = part.headers

		part_struct.body = ''
		part.on_data do |data|
			part_struct.body << data
		end

		part.on_end do
			@response_multipart << part_struct
		end
	end

	parser.write @response.body

	parser.ended?.should be_true
	@response_multipart.should_not be_empty
end

Then /response body should be CRLF endend lines like/ do |body|
	@response.body.should match(body)
	@response.body.each_line do |line|
		line[-2,2].should == "\r\n"
	end
end

Then /response body should be CRLF endend lines$/ do |body|
	@response.body.should == body.gsub("\n", "\r\n") + "\r\n"
end

Then /response status should be (.*)/ do |status|
	@response.status.should == status.to_i
end

Then /response content type should be (.*)/ do |content_type|
	@response.header['Content-Type'].first.should == content_type
end

Then /response mime type should be (.*)/ do |mime_type|
	step "response content type should be #{mime_type}"
end

Then /^([^ ]+) part (.*) header should be (.*)/ do |part, header, value|
	@response_multipart[part_no(part)].headers[header.downcase].should == value
end

Then /^([^ ]+) part body should be CRLF endend lines$/ do |part, body|
	@response_multipart[part_no(part)].body.should == body.gsub("\n", "\r\n")
end

Then /^([^ ]+) part body should be CRLF endend lines like$/ do |part, body|
	pbody = @response_multipart[part_no(part)].body
	pbody.should match(body)
end

Then /response should contain (.*) image of size (.*)x(.*)/ do |format, width, height|
	mime = @response.header['Content-Type'].first
	data = @response.body
	fail("expecte image got #{mime}: #{data}") unless mime =~ /^image\//

	@image.destroy! if @image
	@image = Magick::Image.from_blob(data).first

	@image.format.should == format
	@image.columns.should == width.to_i
	@image.rows.should == height.to_i
end


Then /(.*) part should contain (.*) image of size (.*)x(.*)/ do |part, format, width, height|
	mime = @response_multipart[part_no(part)].headers['content-type']
	data = @response_multipart[part_no(part)].body

	mime.should match /^image\//
	data.should_not be_empty

	@image.destroy! if @image
	@image = Magick::Image.from_blob(data).first

	@image.format.should == format
	@image.columns.should == width.to_i
	@image.rows.should == height.to_i
end

Then /saved response body will be smaller than response body/ do
	@saved_response_body.length.should < @response.body.length
end

And /response will be saved as (.*) for human inspection/ do |file|
	data = @response.body
	(support_dir + file).open('w'){|f| f.write(data)}
end

And /(.*) part body will be saved as (.*) for human inspection/ do |part, file|
	data = @response_multipart[part_no(part)].body
	(support_dir + file).open('w'){|f| f.write(data)}
end

And /that image pixel at (.*)x(.*) should be of color ([^ ]+)$/ do |x, y, color|
	@image.pixel_color(x.to_i, y.to_i).should == Magick::Pixel.from_color(color)
end

And /that image pixel at (.*)x(.*) should be of color ([^ ]+) with fuzz (.*)%/ do |x, y, color, fuzz|
	p1 = @image.pixel_color(x.to_i, y.to_i)
	p2 = Magick::Pixel.from_color(color)
	fuzz = fuzz.to_f / 100

	diff =
		((p1.red - p2.red).abs.to_f / Magick::QuantumRange) / 3 +
		((p1.green - p2.green).abs.to_f / Magick::QuantumRange) / 3 +
		((p1.blue - p2.blue).abs.to_f / Magick::QuantumRange) / 3

	diff.should < fuzz

	# this does not work :/
	#@image.pixel_color(x.to_i, y.to_i).fcmp(Magick::Pixel.from_color(color), p(fuzz.to_f)).should == true
end

And /that image should be (.*) bit image/ do |bits|
	if @image.depth < 8
		(@image.depth * 8).should == bits.to_i # newer versions return 1 for 8 bit?!
	else
		@image.depth.should == bits.to_i
	end
end

And /there should be no leaked images/ do
	Integer(http_client.get_content("http://localhost:3100/stats/images_loaded").strip).should == 0
end

And /there should be maximum (.*) images loaded during single request/ do |max|
	Integer(http_client.get_content("http://localhost:3100/stats/max_images_loaded").strip).should <= max.to_i
end

And /response body should be JSON encoded/ do
	@json = JSON.load(@response.body)
end

And /response JSON should contain key (.*) of value (.*)/ do |key, value|
	@json[key].should == value
end

And /response JSON should contain key (.*) of integer value (.*)/ do |key, value|
	@json[key].should == value.to_i
end

