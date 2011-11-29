Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT original image to URL in format
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

	Scenario: Transparent image to JPEG handling - default background color white
		Given test-transparent.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,JPEG
		Then response status will be 200
		And I will get multipart response
		And first part body will be saved as test-transparent-default.png for human inspection
		And first part will contain JPEG image of size 128x128
		And that image pixel at 32x32 will be of color white
		And there will be no leaked images

	Scenario: Fit thumbnailing method
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,PNG
		Then response status will be 200
		And I will get multipart response
		And first part will contain PNG image of size 91x128
		And there will be no leaked images

	Scenario: Pad thumbnailing method - default background color white
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG
		Then response status will be 200
		And I will get multipart response
		And first part body will be saved as test-pad.png for human inspection
		And first part will contain PNG image of size 128x128
		And that image pixel at 2x2 will be of color white
		And there will be no leaked images

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
		Resource '/blah' not found
		"""

	Scenario: Reporitng of missing resource for PUT
		When I do PUT request http://localhost:3100/blah/thumbnail/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG
		Then response status will be 404
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Resource '/blah/thumbnail/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG' not found
		"""

	Scenario: Reporitng of unsupported media type
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG
		Then response status will be 415
		And response content type will be text/plain
		And response body will be CRLF endend lines like
		"""
		Error: Thumbnailer::UnsupportedMediaTypeError: Magick::ImageMagickError:
		"""

	Scenario: Reporitng of bad thumbanil spec format - missing param
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,PNG
		Then response status will be 500
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: ThumbnailSpecs::BadThubnailSpecFormat: missing argument in: crop,128,PNG
		"""

	Scenario: Reporitng of bad thumbanil spec format - bad options format
		Given test.txt file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,128,128,PNG,fas-fda
		Then response status will be 500
		And response content type will be text/plain
		And response body will be CRLF endend lines
		"""
		Error: ThumbnailSpecs::BadThubnailSpecFormat: missing option key or value in: fas-fda
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
		Error: ArgumentError: invalid result dimension (0, 0 given)
		"""
		Then third part will contain JPEG image of size 16x32
		And third part mime type will be image/jpeg
		And there will be no leaked images

