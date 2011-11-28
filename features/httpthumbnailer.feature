Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT original image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]+]+

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then I will get multipart response
		Then first part mime type will be image/png
		And first part will contain PNG image of size 16x16

	Scenario: Multiple thumbnails
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG/crop,4,8,JPG/crop,16,32,JPEG
		Then I will get multipart response
		Then first part mime type will be image/png
		And first part will contain PNG image of size 16x16
		Then second part mime type will be image/jpeg
		And second part will contain JPEG image of size 4x8
		Then third part mime type will be image/jpeg
		And third part will contain JPEG image of size 16x32

	@test
	Scenario: Transparent image to JPEG handling - default background color white
		Given test-transparent.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,JPEG
		Then I will get multipart response
		And first part body will be saved as test-transparent-default.png for human inspection
		And first part will contain JPEG image of size 128x128
		And that image pixel at 32x32 will be of color white

	Scenario: Fit thumbnailing method
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,PNG
		Then I will get multipart response
		And first part will contain PNG image of size 91x128

	Scenario: Pad thumbnailing method - default background color white
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG
		Then I will get multipart response
		And first part body will be saved as test-pad.png for human inspection
		And first part will contain PNG image of size 128x128
		And that image pixel at 2x2 will be of color white

	Scenario: Pad thumbnailing method with specified background color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/pad,128,128,PNG,background-color:green
		Then I will get multipart response
		And first part body will be saved as test-pad-background-color.png for human inspection
		And first part will contain PNG image of size 128x128
		And that image pixel at 2x2 will be of color green

