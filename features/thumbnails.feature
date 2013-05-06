Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT an image to URL in format
	/thumbnails[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]+]+

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@multipart
	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And that image should be 8 bit image
		And first part mime type should be image/png

	@multipart
	Scenario: Multiple thumbnails
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,4,8,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part mime type should be image/png
		Then second part should contain JPEG image of size 4x8
		And second part mime type should be image/jpeg
		Then third part should contain JPEG image of size 16x32
		And third part mime type should be image/jpeg

	@input_size
	Scenario: Thumbnails of width or height input should have input image width or height
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,input,16,jpeg/crop,4,input,png/crop,input,input,png
		Then response status should be 200
		And I should get multipart response
		Then first part should contain JPEG image of size 509x16
		And first part mime type should be image/jpeg
		Then second part should contain PNG image of size 4x719
		And second part mime type should be image/png
		Then third part should contain PNG image of size 509x719
		And third part mime type should be image/png

	@leaking
	Scenario: Image leaking on error
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,0,0,png/fit,0,0,jpeg/pad,0,0,jpeg
		Then response status should be 200
		And I should get multipart response
		And first part content type should be text/plain
		And second part content type should be text/plain
		And third part content type should be text/plain

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format problems
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,2,2,png/crop,128,bogous,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: bad dimmension value: bogous
		"""

	@error_handling
	Scenario: Reporitng of image thumbnailing errors
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,0,0,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part mime type should be image/png
		And second part content type should be text/plain
		And second part body should be CRLF endend lines
		"""
		Error: at least one image dimension is zero: 0x0
		"""
		Then third part should contain JPEG image of size 16x32
		And third part mime type should be image/jpeg

	@resources
	Scenario: Memory limits exhausted while thumbnailing
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,16000,16000,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part mime type should be image/png
		And second part content type should be text/plain
		And second part body should be CRLF endend lines like
		"""
		Error: image too large: cache resources exhausted
		"""
		Then third part should contain JPEG image of size 16x32
		And third part mime type should be image/jpeg

	@hint
	Scenario: Hint on input image mime type
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Content-Type header should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Content-Type header should be image/png

