module Rack
	class UnhandledRequest
		class UnhandledRequestError < ArgumentError
      attr_reader :uri
			def initialize(uri)
        @uri = uri
				super "request for URI '#{uri}' was not handled by the server"
			end
		end

		def initialize(app)
			@app = app
		end

		def call(env)
			status, headers, body = @app.call(env)
			raise UnhandledRequestError, env['SCRIPT_NAME'] + env['PATH_INFO'] if body == [] and (status == 200 or status == 404)
			[status, headers, body]
		end
	end
end

