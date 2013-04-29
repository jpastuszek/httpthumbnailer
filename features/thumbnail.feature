Feature: Generating single thumbnail with PUT request
	In order to generate a single image thumbnail
	A user must PUT an image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>

	Background:
		Given httpthumbnailer log is empty
		Given httpthumbnailer server is running at http://localhost:3100/

	@thumbnail @test
	Scenario: Single thumbnail
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/crop,16,16,PNG
		Then response status will be 200
		Then response will contain PNG image of size 16x16
		And response mime type will be image/png
		And there will be no leaked images

