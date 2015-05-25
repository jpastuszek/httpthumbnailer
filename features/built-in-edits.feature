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

	@edits @built-in @crop
	Scenario: Cropping
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.1,0.0,0.8,1.0
		Then response status should be 200
		Then response should contain PNG image of size 73x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.0,0.1,1.0,0.8
		Then response status should be 200
		Then response should contain PNG image of size 113x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.1,0.1,0.8,0.8
		Then response status should be 200
		Then response should contain PNG image of size 91x128

	@edits @built-in @crop
	Scenario: Cropping with noop values
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.0,0.0,1.0,1.0
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,-20.2,-20.2,1.8,10.8
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.0,0.0,1.8,10.8
		Then response status should be 200
		Then response should contain PNG image of size 91x128

	@edits @built-in @crop
	Scenario: Cropping normalization
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.2,0.0,10,1.0
		Then response status should be 200
		Then response should contain PNG image of size 73x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.0,0.2,1.0,10
		Then response status should be 200
		Then response should contain PNG image of size 113x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.2,0.2,10,10
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,-10,0.0,0.8,1.0
		Then response status should be 200
		Then response should contain PNG image of size 73x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.0,-10,1.0,0.8
		Then response status should be 200
		Then response should contain PNG image of size 113x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,-10,-10,0.8,0.8
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.2,0.2,1.0,1.0
		Then response status should be 200
		Then response should contain PNG image of size 91x128
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!crop,0.2,0.2,-1.0,-1.0
		Then response status should be 200
		Then response should contain PNG image of size 128x128

	@edits @built-in @pixelate
	Scenario: Pixelating given region
		Given test2.png file content as request body
		When I do PUT request http://localhost:3100/thumbnail/limit,1280,1280,png!pixelate,0.4,0.4,0.2,0.2,size:0.1
		Then response status should be 200
		Then response should contain PNG image of size 800x600
		And that image pixel at 319x239 should be of color #bc1616
		And that image pixel at 320x240 should be of color #862e2e
		And that image pixel at 419x339 should be of color #862e2e
		And that image pixel at 420x340 should be of color #871007
		And that image pixel at 479x359 should be of color #871007
		And that image pixel at 480x360 should be of color #6a0e15

