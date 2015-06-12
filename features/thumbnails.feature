Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT an image to URL in format
	/thumbnails[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]*]*

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@multipart
	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,24,png
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x24
		And that image should be 8 bit image
		And first part Content-Type header should be image/png
		And first part X-Image-Width header should be 16
		And first part X-Image-Height header should be 24

	@multipart
	Scenario: Multiple thumbnails
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,4,8,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part Content-Type header should be image/png
		And first part X-Image-Width header should be 16
		And first part X-Image-Height header should be 16
		Then second part should contain JPEG image of size 4x8
		And second part Content-Type header should be image/jpeg
		And second part X-Image-Width header should be 4
		And second part X-Image-Height header should be 8
		Then third part should contain JPEG image of size 16x32
		And third part Content-Type header should be image/jpeg
		And third part X-Image-Width header should be 16
		And third part X-Image-Height header should be 32

	@input_size
	Scenario: Thumbnails of width or height input should have input image width or height
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,input,16,jpeg/crop,4,input,png/crop,input,input,png
		Then response status should be 200
		And I should get multipart response
		Then first part should contain JPEG image of size 509x16
		Then second part should contain PNG image of size 4x719
		Then third part should contain PNG image of size 509x719

	@leaking
	Scenario: Image leaking on error
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,0,0,png/fit,0,0,jpeg/pad,0,0,jpeg
		Then response status should be 200
		And I should get multipart response
		And first part Content-Type header should be text/plain
		And second part Content-Type header should be text/plain
		And third part Content-Type header should be text/plain

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad dimension value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,4,4,png/crop,128,bogous,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		bad dimension value: bogous
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - missing param
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,4,4,png/crop,128,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		missing argument in: crop,128,png
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad options format
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,4,4,png/crop,128,128,png,fas-fda
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		missing option key or value in: fas-fda
		"""

	@error_handling
	Scenario: Reporitng of bad method value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,4,4,png/blah,128,128,png
		Then response status should be 200
		And I should get multipart response
		And second part Content-Type header should be text/plain
		And second part body should be CRLF endend lines
		"""
		thumbnail method 'blah' is not supported
		"""
		And second part Status header should be 400

	@error_handling
	Scenario: Reporitng of image thumbnailing errors
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,0,0,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part Content-Type header should be image/png
		And second part Content-Type header should be text/plain
		And second part body should be CRLF endend lines
		"""
		at least one image dimension is zero: 0x0
		"""
		And second part Status header should be 400
		Then third part should contain JPEG image of size 16x32
		And third part Content-Type header should be image/jpeg

	@error_handling
	Scenario: Reporitng of bat thumbnail option value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,4,4,png,float-x:xxx/crop,128,128,png
		Then response status should be 200
		And I should get multipart response
		And first part Content-Type header should be text/plain
		And first part body should be CRLF endend lines
		"""
		error while thumbnailing with method 'crop': expected argument 'float-x' to be a float, got: xxx
		"""

	@resources
	Scenario: Memory limits exhausted while thumbnailing
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png/crop,16000,16000,jpeg/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 16x16
		And first part Content-Type header should be image/png
		And second part Content-Type header should be text/plain
		And second part body should be CRLF endend lines like
		"""
		image too large: cache resources exhausted
		"""
		And second part Status header should be 413
		Then third part should contain JPEG image of size 16x32
		And third part Content-Type header should be image/jpeg

	@hint @input
	Scenario: Hint on input image mime type
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Mime-Type header should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Mime-Type header should be image/png

	@hint @input
	Scenario: Hint on input image size
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Width header should be 9911
		And X-Input-Image-Height header should be 14000

