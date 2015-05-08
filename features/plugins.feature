Feature: Loading plugins
	To make it easy to extend HTTP Thumbnailer plugins can be written and loaded from given directories

	@plugins @thumbnailing_methods
	Scenario: Loading additional thumbnailing methods from plugins - with sub dirs
		Given httpthumbnailer plugins dir test_plugins
		Given httpthumbnailer server is running at http://localhost:3100/
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/blur,16,24,png
		Then response status should be 200
		Then response should contain PNG image of size 16x23
		When I do PUT request http://localhost:3100/thumbnail/cut,16,24,jpeg
		Then response status should be 200
		Then response should contain JPEG image of size 16x23

	@plugins @thumbnailing_methods
	Scenario: Loading additional thumbnailing methods from plugins - with given dirs
		Given httpthumbnailer plugins dir test_plugins/p1
		Given httpthumbnailer plugins dir test_plugins/p2
		Given httpthumbnailer server is running at http://localhost:3100/
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/blur,16,24,png
		Then response status should be 200
		Then response should contain PNG image of size 16x23
		When I do PUT request http://localhost:3100/thumbnail/cut,16,24,jpeg
		Then response status should be 200
		Then response should contain JPEG image of size 16x23

