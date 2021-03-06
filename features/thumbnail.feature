Feature: Generating single thumbnail with PUT request
	In order to generate a single image thumbnail
	A user must PUT an image to URL in format
	/thumbnail/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]*

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@test
	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,24,png
		Then response status should be 200
		Then response should contain PNG image of size 16x24
		And that image should be 8 bit image
		And Content-Type header should be image/png
		And X-Image-Width header should be 16
		And X-Image-Height header should be 24
		When I do PUT request http://localhost:3100/thumbnail/crop,16,24,jpeg
		Then response status should be 200
		Then response should contain JPEG image of size 16x24
		And that image should be 8 bit image
		And Content-Type header should be image/jpeg
		And X-Image-Width header should be 16
		And X-Image-Height header should be 24

	@transparent
	Scenario: Transparent image to JPEG handling - default background color white
		Given test-transparent.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,jpeg
		Then response status should be 200
		And response will be saved as test-transparent-default.png for human inspection
		Then response should contain JPEG image of size 128x128
		And that image pixel at 32x32 should be of color white

	@input_format
	Scenario: Thumbnails of format input should have same format as input image
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,4,8,input
		Then response status should be 200
		Then response should contain JPEG image of size 4x8
		And response mime type should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,4,8,input
		Then response status should be 200
		Then response should contain PNG image of size 4x8
		And that image should be 8 bit image
		And response mime type should be image/png

	@input_size
	Scenario: Thumbnails of width or height input should have input image width or height
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,input,16,png
		Then response status should be 200
		Then response should contain PNG image of size 509x16
		And response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,4,input,png
		Then response status should be 200
		Then response should contain PNG image of size 4x719
		And response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,input,input,png
		Then response status should be 200
		Then response should contain PNG image of size 509x719
		And response mime type should be image/png

	@fit
	Scenario: Fit thumbnailing method
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,1024,1024,png
		Then response status should be 200
		Then response should contain PNG image of size 725x1024

	@limit
	Scenario: Limit thumbnailing method should reduce image size when needed
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/limit,128,128,png
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/limit,1024,1024,png
		Then response status should be 200
		Then response should contain PNG image of size 509x719

	@pad @transparent
	Scenario: Pad thumbnailing method - default background color white
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,png
		Then response status should be 200
		And response will be saved as test-pad.png for human inspection
		Then response should contain PNG image of size 128x128
		And that image pixel at 2x2 should be of color white

	@pad @transparent
	Scenario: Pad thumbnailing method with specified background color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,png,background-color:green
		Then response status should be 200
		And response will be saved as test-pad-background-color.png for human inspection
		Then response should contain PNG image of size 128x128
		And that image pixel at 2x2 should be of color green

	@error_handling
	Scenario: Reporitng of unsupported media type
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png
		Then response status should be 415
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		unsupported media type: no decode delegate for this image format
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad dimension value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,bogous,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		height value 'bogous' is not an integer or 'input' in spec 'crop,128,bogous,png'
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - missing param
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		missing format argument in spec 'crop,128,png'
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad options format
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png,fas-xyz
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		missing option value for key 'fas-xyz' in spec 'crop,128,128,png,fas-xyz'
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil option value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png,float-x:xxx
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		error while thumbnailing with method 'crop': expected argument 'float-x' to be a float, got: xxx
		"""

	@error_handling
	Scenario: Reporitng of bad method value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/blah,128,128,png
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		thumbnail method 'blah' is not supported
		"""

	@error_handling
	Scenario: Reporitng of image thumbnailing errors
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,0,0,jpeg
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		at least one image dimension is zero: 0x0
		"""

	@error_handling
	Scenario: Reporitng of bad color value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,240,200,input,background-color:ff11
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		invalid color name: ff11
		"""

	@optimization
	Scenario: Handing of large image data - possible thanks to loading size optimization
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,png
		Then response status should be 200
		Then response should contain PNG image of size 16x16

	@resources
	Scenario: Memory limits exhausted while loading - no loading optimization possible
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,7000,7000,png
		Then response status should be 413
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		image too large: cache resources exhausted
		"""

	@resources
	Scenario: Memory limits exhausted while thumbnailing
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16000,16000,jpeg
		Then response status should be 413
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		image too large: cache resources exhausted
		"""

	@quality
	Scenario: Quality option - JPEG
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg,quality:10
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg,quality:80
		Then saved response body will be smaller than response body
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg,quality:90
		Then saved response body will be smaller than response body

	@quality
	Scenario: Quality option - JPEG - default 85
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg,quality:84
		When I save response body
		Then response mime type should be image/jpeg
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg
		Then saved response body will be smaller than response body
		Then response mime type should be image/jpeg
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,jpeg,quality:86
		Then saved response body will be smaller than response body
		Then response mime type should be image/jpeg

	@quality
	Scenario: Quality option - PNG (XY where X - zlib compresion level, Y - filter)
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png,quality:90
		When I save response body
		Then response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png,quality:50
		Then saved response body will be smaller than response body
		Then response mime type should be image/png
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,png,quality:10
		Then saved response body will be smaller than response body
		Then response mime type should be image/png

	@hint @input
	Scenario: Hint on input image mime type
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Mime-Type header should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Mime-Type header should be image/png

	@hint @input
	Scenario: Hint on input image size
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,png
		Then response status should be 200
		And X-Input-Image-Width header should be 9911
		And X-Input-Image-Height header should be 14000

