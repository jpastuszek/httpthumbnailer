Feature: Applying edits before thumbnailing the image
	In order apply aditional edits before generating a thumbnail
	A user must PUT an image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>[!<edit name>[,<edit arg>]*[,<edit option key>:<edit option value>]*]*
	/thumbnails[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]*[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@edits @single
	Scenario: Single edit
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,90
		Then response status should be 200
		Then response should contain PNG image of size 128x91

	@edits @multiple
	Scenario: Multiple edits
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,90!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 128x117

	@edits @multipart
	Scenario: Edits usied with multipart API
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/fit,32,32,png!rotate,90/fit,128,128,jpeg!rotate,90!rotate,30/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 32x23
		And first part Content-Type header should be image/png
		Then second part should contain JPEG image of size 128x117
		And second part Content-Type header should be image/jpeg
		Then third part should contain JPEG image of size 16x32
		And third part Content-Type header should be image/jpeg

	@edits
	Scenario: Passing options to edits
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,30,background-color:red
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color red
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,30,background-color:blue
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

	@edits
	Scenario: Edits using thumbnail spec options
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png,background-color:red!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color red
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png,background-color:blue!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

	@edits @multipart
	Scenario: Edits should only apply to single image with multipart
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/fit,128,128,png!rotate,90/fit,128,128,jpeg!rotate,30/fit,128,128,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 128x91
		Then second part should contain JPEG image of size 117x128
		Then third part should contain JPEG image of size 91x128

	@edits @error_handling
	Scenario: Reporitng of edit spec format - no value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png!rotate
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		error while applying edit 'rotate': expected argument 'angle' to be a float but got no value
		"""

	@edits @error_handling
	Scenario: Reporitng of edit spec format - bad value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png!rotate,xxx
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		error while applying edit 'rotate': expected argument 'angle' to be a float, got: xxx
		"""

	@edits @error_handling
	Scenario: Reporitng of edit spec format - extra values
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png!rotate,90,xxx,yyy
		Then response status should be 200
		Then response should contain PNG image of size 128x128

