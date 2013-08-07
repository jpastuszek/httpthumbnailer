Feature: Identify API endpoint
	Identify API allows for image identification.

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@identify
	Scenario: Identifying of image content type
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/identify
		Then response status should be 200
		And response content type should be application/json
		And response body should be JSON encoded
		And response JSON should contain key contentType of value image/jpeg
		Given test.png file content as request body
		When I do PUT request http://localhost:3100/identify
		Then response status should be 200
		And response content type should be application/json
		And response body should be JSON encoded
		And response JSON should contain key contentType of value image/png

	@identify
	Scenario: Identifying of image width and height
		Given test-large.jpg file content as request body
		When I do PUT request http://localhost:3100/identify
		Then response status should be 200
		And response content type should be application/json
		And response body should be JSON encoded
		And response JSON should contain key width of integer value 9911
		And response JSON should contain key height of integer value 14000

