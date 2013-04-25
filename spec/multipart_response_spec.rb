require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'features/support/multipart_response'

describe MultipartResponse do
	describe "parsing" do
		it "should privide preamble, parts with headers and epilogue" do
			content_type_header = 'multipart/mixed; boundary="cut here"'
			body = 
"""hello
--cut here
Content-Type: text/plain

part 1
--cut here
Content-Type: text/html
Content-Transfer-Encoding: base64

part 2
--cut here
part 3
--cut here--
world""".gsub!("\n", "\r\n")
			
			mr = MultipartResponse.new(content_type_header, body)
			mr.preamble.should == "hello"

			mr.parts[0].body.should == "part 1"
			mr.parts[0].header['Content-Type'].should == "text/plain"

			mr.parts[1].body.should == "part 2"
			mr.parts[1].header['Content-Type'].should == "text/html"
			mr.parts[1].header['Content-Transfer-Encoding'].should == "base64"

			mr.parts[2].body.should == "part 3"

			mr.epilogue.should == "world"
		end

		it "should privide nil preamble if no prologue sent" do
			content_type_header = 'multipart/mixed; boundary="cut here"'
			body = 
"""--cut here
part 1
--cut here--""".gsub!("\n", "\r\n")
			
			mr = MultipartResponse.new(content_type_header, body)
			mr.preamble.should be_nil
		end

		it "should privide nil epilogue if no epilogue sent" do
			content_type_header = 'multipart/mixed; boundary="cut here"'
			body = 
"""--cut here
part 1
--cut here--""".gsub!("\n", "\r\n")
			
			mr = MultipartResponse.new(content_type_header, body)
			mr.epilogue.should be_nil
		end

		it "should provide default mime type of text/plain if no Content-Type header specified" do
			content_type_header = 'multipart/mixed; boundary="cut here"'
			body = 
"""--cut here
part 1
--cut here--""".gsub!("\n", "\r\n")
			
			mr = MultipartResponse.new(content_type_header, body)
			mr.part[0].header['Content-Type'].should == 'text/plain'
		end

		it "should fail with MultipartResponse::NoBoundaryFoundInContentTypeError if no boundary specified in content type header" do
			lambda {
				MultipartResponse.new("fas", "")
			}.should raise_error MultipartResponse::NoBoundaryFoundInContentTypeError
		end
	end
	
	it "provides part alias" do
		content_type_header = 'multipart/mixed; boundary="cut here"'
		body = 
"""--cut here
part 1
--cut here
part 2
--cut here
part 3
--cut here--""".gsub!("\n", "\r\n")
		
		mr = MultipartResponse.new(content_type_header, body)
		mr.part[0].body.should == "part 1"
		mr.part[1].body.should == "part 2"
		mr.part[2].body.should == "part 3"
	end
end
