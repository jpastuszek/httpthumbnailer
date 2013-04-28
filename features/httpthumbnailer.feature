Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT an image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]+]+

	Background:
		Given httpthumbnailer log is empty
		Given httpthumbnailer server is running at http://localhost:3100/

	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		And there will be no leaked images

	Scenario: Multiple thumbnails
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,4,8,JPG/crop,16,32,JPEG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		Then second part will contain JPEG image of size 4x8
		And second part mime type will be image/jpeg
		Then third part will contain JPEG image of size 16x32
		And third part mime type will be image/jpeg
		And there will be no leaked images

	@transparent
	Scenario: Transparent image to JPEG handling - default background color white
		Given test-transparent.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,JPEG
		Then response status will be 200
		And I will get multipart response
		And first part body will be saved as test-transparent-default.png for human inspection
		And first part will contain JPEG image of size 128x128
		And that image pixel at 32x32 will be of color white
		And there will be no leaked images

	Scenario: Thumbnails of format INPUT should have same format as input image - for JPEG
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,4,8,INPUT/crop,16,32,INPUT
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		Then second part will contain JPEG image of size 4x8
		And second part mime type will be image/jpeg
		Then third part will contain JPEG image of size 16x32
		And third part mime type will be image/jpeg

	Scenario: Thumbnails of format INPUT should have same format as input image - for PNG
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,JPEG/crop,4,8,INPUT/crop,16,32,INPUT
		Then response status will be 200
		And I will get multipart response
		Then first part will contain JPEG image of size 16x16
		And first part mime type will be image/jpeg
		Then second part will contain PNG image of size 4x8
		And second part mime type will be image/png
		Then third part will contain PNG image of size 16x32
		And third part mime type will be image/png

	Scenario: Thumbnails of width or height INPUT will have input image width or height
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,INPUT,16,JPEG/crop,4,INPUT,PNG/crop,INPUT,INPUT,PNG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain JPEG image of size 509x16
		And first part mime type will be image/jpeg
		Then second part will contain PNG image of size 4x719
		And second part mime type will be image/png
		Then third part will contain PNG image of size 509x719
		And third part mime type will be image/png

	Scenario: Fit thumbnailing method
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,PNG
		Then response status will be 200
		And I will get multipart response
		And first part will contain PNG image of size 91x128
		And there will be no leaked images

	@transparent
	Scenario: Pad thumbnailing method - default background color white
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG
		Then response status will be 200
		And I will get multipart response
		And first part body will be saved as test-pad.png for human inspection
		And first part will contain PNG image of size 128x128
		And that image pixel at 2x2 will be of color white
		And there will be no leaked images

	@transparent
	Scenario: Pad thumbnailing method with specified background color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG,background-color:green
		Then response status will be 200
		And I will get multipart response
		And first part body will be saved as test-pad-background-color.png for human inspection
		And first part will contain PNG image of size 128x128
		And that image pixel at 2x2 will be of color green
		And there will be no leaked images

	Scenario: Image leaking on error
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG
		Then response status will be 200
		And I will get multipart response
		And first part content type will be text/plain
		And second part content type will be text/plain
		And third part content type will be text/plain
		And there will be no leaked images

	Scenario: Reporitng of missing resource for GET
		When I do GET request http://localhost:3100/blah
		Then response status will be 404
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: request for URI '/blah' was not handled by the server
		"""

	Scenario: Reporitng of missing resource for PUT
		When I do PUT request http://localhost:3100/blah/thumbnail/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG
		Then response status will be 404
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: request for URI '/blah/thumbnail/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG' was not handled by the server
		"""

	Scenario: Reporitng of unsupported media type
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG
		Then response status will be 415
		And response content type will be text/plain
		And response body will be CRLF endend lines like
		"""
		Error: unsupported media type: no decode delegate for this image format
		"""

	Scenario: Reporitng of bad thumbanil spec format - bad dimmension value
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,bogous,PNG
		Then response status will be 500
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: bad dimmension value: bogous
		"""

	Scenario: Reporitng of bad thumbanil spec format - missing param
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,PNG
		Then response status will be 500
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: missing argument in: crop,128,PNG
		"""

	Scenario: Reporitng of bad thumbanil spec format - bad options format
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,fas-fda
		Then response status will be 500
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: missing option key or value in: fas-fda
		"""

	Scenario: Reporitng of image thumbnailing errors
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,0,0,JPG/crop,16,32,JPEG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		And second part content type will be text/plain
		And second part body will be CRLF endend lines
		"""
		Error: invalid result dimension (0, 0 given)
		"""
		Then third part will contain JPEG image of size 16x32
		And third part mime type will be image/jpeg
		And there will be no leaked images

	Scenario: Handing of large image data - possible thanks to loading size optimization
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,32,32,JPEG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		Then second part will contain JPEG image of size 32x32
		And second part mime type will be image/jpeg
		And there will be no leaked images

	@resources
	Scenario: Memory limits exhausted while loading
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,7000,7000,PNG
		Then response status will be 413
		And response content type will be text/plain
		And response body will be CRLF endend lines like
		"""
		Error: image too large: cache resources exhausted
		"""
		And there will be no leaked images

	@resources
	Scenario: Memory limits exhausted while thumbnailing
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,16000,16000,JPG/crop,16,32,JPEG
		Then response status will be 200
		And I will get multipart response
		Then first part will contain PNG image of size 16x16
		And first part mime type will be image/png
		And second part content type will be text/plain
		And second part body will be CRLF endend lines like
		"""
		Error: image too large: cache resources exhausted
		"""
		Then third part will contain JPEG image of size 16x32
		And third part mime type will be image/jpeg
		And there will be no leaked images

	Scenario: Quality option - JPEG
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:10/crop,32,32,JPG,quality:80/crop,32,32,JPEG,quality:90
		Then response status will be 200
		And I will get multipart response
		And first part mime type will be image/jpeg
		And second part mime type will be image/jpeg
		And third part mime type will be image/jpeg
		Then first part will contain body smaller than second part
		Then second part will contain body smaller than third part

	Scenario: Quality option - JPEG - default 85
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,32,32,JPEG,quality:84/crop,32,32,JPG/crop,32,32,JPEG,quality:86
		Then response status will be 200
		And I will get multipart response
		And first part mime type will be image/jpeg
		And second part mime type will be image/jpeg
		And third part mime type will be image/jpeg
		Then first part will contain body smaller than second part
		Then second part will contain body smaller than third part

	Scenario: Quality option - PNG (XY where X - zlib compresion level, Y - filter)
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,64,64,PNG,quality:90/crop,64,64,PNG,quality:50/crop,64,64,PNG,quality:10
		Then response status will be 200
		And I will get multipart response
		And first part mime type will be image/png
		And second part mime type will be image/png
		And third part mime type will be image/png
		Then first part will contain body smaller than second part
		Then second part will contain body smaller than third part
		And there will be no leaked images

	Scenario: Hint on input image mime type - JPEG
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status will be 200
		And X-Input-Image-Content-Type header will be image/jpeg

	Scenario: Hint on input image mime type - PNG
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status will be 200
		And X-Input-Image-Content-Type header will be image/png

