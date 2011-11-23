Feature: Generating set of thumbnails with single PUT request
	In order to generate a set of image thumbnails
	A user must PUT original image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]+]+

	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request /thumbnail/crop,16,16,PNG
		Then I will get multipart response
		Then first part mime type will be image/png
		And first part will contain PNG image of size 16x16

	Scenario: Multiple thumbnails
		Given test.jpg file content as request body
		When I do PUT request /thumbnail/crop,16,16,PNG/crop,4,8,JPG/crop,16,32,JPEG
		Then I will get multipart response
		Then first part mime type will be image/png
		And first part will contain PNG image of size 16x16
		Then second part mime type will be image/jpeg
		And second part will contain JPEG image of size 4x8
		Then third part mime type will be image/jpeg
		And third part will contain JPEG image of size 16x32
