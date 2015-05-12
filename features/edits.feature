Feature: Applying edits before thumbnailing the image
	In order apply aditional edits before generating a thumbnail
	A user must PUT an image to URL in format
	/thumbnail[/<thumbnail type>,<width>,<height>,<format>[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*
	/thumbnails[/<thumbnail type>,<width>,<height>,<format>[,<option key>:<option value>]*[!<edit name>[,<edit arg>]*[,<edit option>:<edit option value>]*]*

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	Scenario: Single edit
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,90
		Then response status should be 200
		Then response should contain PNG image of size 128x91

	Scenario: Multiple edits
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,90!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 128x117

	Scenario: Edits usied with multipart API
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnails/fit,32,32,png!rotate,90/fit,128,128,jpeg!rotate,90!rotate,30/crop,16,32,jpeg
		Then response status should be 200
		And I should get multipart response
		Then first part should contain PNG image of size 32x23
		And first part Content-Type header should be image/png
		Then second part should contain JPEG image of size 128x117
		And second part Content-Type header should be image/jpeg
		Then third part should contain JPEG image of size 16x32
		And third part Content-Type header should be image/jpeg

	Scenario: Passing options to edits
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,30,background-color:red
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color red
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png!rotate,30,background-color:blue
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

	Scenario: Edits using thumbnail spec options
		Given test.jpg file content as request body
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png,background-color:red!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color red
		When I do PUT request http://localhost:3100/thumbnail/fit,128,128,png,background-color:blue!rotate,30
		Then response status should be 200
		Then response should contain PNG image of size 117x128
		And that image pixel at 4x4 should be of color blue

