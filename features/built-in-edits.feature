Feature: Built in edits
	A set of built-in edits is available out of the box

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	@edits @built-in @rotate
	Scenario: Rotating
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,90
		Then response status should be 200
		Then response should contain PNG image of size 128x91

	@edits @built-in @rotate
	Scenario: Rotating with background-color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,30,background-color:blue
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

	@edits @built-in @rotate
	Scenario: Rotating with inherited background-color
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png,background-color:blue!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

	@edits @built-in @rotate
	Scenario: Rotating with negative angle
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,-30
		Then response status should be 200
		Then response should contain PNG image of size 117x128

	@edits @built-in @rotate
	Scenario: Rotating with noop value
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,0
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,360
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,-360
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,720
		Then response status should be 200
		Then response should contain PNG image of size 91x128
