Before do
	server_start
	@request_body = nil
	@response = nil
	@response_multipart = nil
end

After do
	server_stop
end

Given /(.*) file content as request body/ do |file|
	@request_body = File.open(support_dir + file){|f| f.read }
end

When /I do (.*) request (.*)/ do |method, uri|
	@response = server_request(method, uri, nil, @request_body)
end

Then /I will get multipart response/ do
	@response.header['Content-Type'].first.should match /^multipart/
	@response_multipart = MultipartResponse.new(@response.header['Content-Type'].last, @response.body)
end

Then /(.*) part mime type will be (.*)/ do |part, mime|
	@response_multipart.part[part_no(part)].header['Content-Type'].should == mime
end

Then /(.*) part will contain (.*) image of size (.*)/ do |part, image_type, image_size|
	data = @response_multipart.part[part_no(part)].body

	Open3.popen3('identify -') do |stdin, stdout, stderr| 
		stdin.write data
		stdin.close
		path, type, size, *rest = *stdout.read.split(' ')
		type.should == image_type
		size.should == image_size
	end
end


