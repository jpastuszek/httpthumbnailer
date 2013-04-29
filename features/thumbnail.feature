Feature: Generating single thumbnail with PUT request
	In order to generate a single image thumbnail
	A user must PUT an image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status should be 200
		Then response should contain PNG image of size 16x16
		And response mime type should be image/png

	@transparent
	Scenario: Transparent image to JPEG handling - default background color white
		Given test-transparent.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,JPEG
		Then response status should be 200
		And response will be saved as test-transparent-default.png for human inspection
		Then response should contain JPEG image of size 128x128
		And that image pixel at 32x32 should be of color white

	@input_format
	Scenario: Thumbnails of format INPUT should have same format as input image
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,4,8,INPUT
		Then response status should be 200
		Then response should contain JPEG image of size 4x8
		And response mime type should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,4,8,INPUT
		Then response status should be 200
		Then response should contain PNG image of size 4x8
		And response mime type should be image/png

	@input_size
	Scenario: Thumbnails of width or height INPUT should have input image width or height
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,INPUT,16,PNG
		Then response status should be 200
		Then response should contain PNG image of size 509x16
		And response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,4,INPUT,PNG
		Then response status should be 200
		Then response should contain PNG image of size 4x719
		And response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,INPUT,INPUT,PNG
		Then response status should be 200
		Then response should contain PNG image of size 509x719
		And response mime type should be image/png

	Scenario: Fit thumbnailing method
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,PNG
		Then response status should be 200
		Then response should contain PNG image of size 91x128

	@transparent
	Scenario: Pad thumbnailing method - default background color white
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG
		Then response status should be 200
		And response will be saved as test-pad.png for human inspection
		Then response should contain PNG image of size 128x128
		And that image pixel at 2x2 should be of color white

	@transparent
	Scenario: Pad thumbnailing method with specified background color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG,background-color:green
		Then response status should be 200
		And response will be saved as test-pad-background-color.png for human inspection
		Then response should contain PNG image of size 128x128
		And that image pixel at 2x2 should be of color green

	@error_handling
	Scenario: Reporitng of unsupported media type
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG
		Then response status should be 415
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		Error: unsupported media type: no decode delegate for this image format
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad dimmension value
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,bogous,PNG
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: bad dimmension value: bogous
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - missing param
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,PNG
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: missing argument in: crop,128,PNG
		"""

	@error_handling
	Scenario: Reporitng of bad thumbanil spec format - bad options format
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,fas-fda
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: missing option key or value in: fas-fda
		"""

	@error_handling
	Scenario: Reporitng of image thumbnailing errors
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,0,0,JPG
		Then response status should be 400
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: at least one image dimension is zero: 0x0
		"""

	@optimization
	Scenario: Handing of large image data - possible thanks to loading size optimization
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status should be 200
		Then response should contain PNG image of size 16x16

	@resources
	Scenario: Memory limits exhausted while loading - no loading optimization possible
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,7000,7000,PNG
		Then response status should be 413
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		Error: image too large: cache resources exhausted
		"""

	@resources
	Scenario: Memory limits exhausted while thumbnailing
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16000,16000,JPG
		Then response status should be 413
		And response content type should be text/plain
		And response body should be CRLF endend lines like
		"""
		Error: image too large: cache resources exhausted
		"""

	@quality
	Scenario: Quality option - JPEG
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:10
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPG,quality:80
		Then saved response body will be smaller than response body
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:90
		Then saved response body will be smaller than response body

	@quality
	Scenario: Quality option - JPEG - default 85
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:84
		When I save response body
		Then response mime type should be image/jpeg
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPG
		Then saved response body will be smaller than response body
		Then response mime type should be image/jpeg
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:86
		Then saved response body will be smaller than response body
		Then response mime type should be image/jpeg

	@quality
	Scenario: Quality option - PNG (XY where X - zlib compresion level, Y - filter)
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,quality:90
		When I save response body
		Then response mime type should be image/png
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,quality:50
		Then saved response body will be smaller than response body
		Then response mime type should be image/png
		When I save response body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,quality:10
		Then saved response body will be smaller than response body
		Then response mime type should be image/png

	@hint
	Scenario: Hint on input image mime type
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,PNG
		Then response status should be 200
		And X-Input-Image-Content-Type header should be image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnails/crop,16,16,PNG
		Then response status should be 200
		And X-Input-Image-Content-Type header should be image/png

