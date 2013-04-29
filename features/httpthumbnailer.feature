Feature: HTTP server
	It should behave like valid HTTP server

	Background:
		Given httpthumbnailer server is running at http://localhost:3100/

	Scenario: Reporitng of missing resource for GET
		When I do GET request http://localhost:3100/blah
		Then response status should be 404
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: request for URI '/blah' was not handled by the server
		"""

	Scenario: Reporitng of missing resource for PUT
		When I do PUT request http://localhost:3100/blah/thumbnails/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG
		Then response status should be 404
		And response content type should be text/plain
		And response body should be CRLF endend lines
		"""
		Error: request for URI '/blah/thumbnails/crop,0,0,PNG/fit,0,0,JPG/pad,0,0,JPEG' was not handled by the server
		"""

