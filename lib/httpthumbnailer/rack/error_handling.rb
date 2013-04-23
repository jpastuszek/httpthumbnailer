require 'pp'

module Rack
	class ErrorHandling
		def initialize(app, &block)
			@app = app
		end

		def call(env)
			# save original env
			orig_env = env.dup
			begin
				return @app.call(env)
			rescue => error
				begin
					# reset env to original since it could have been changed
					env.clear
					env.merge!(orig_env)

					# set error so app can handle it
					env["app.error"] = error

					return @app.call(env)
				rescue => fatal
					raise 
				end
			end
		end
	end
end

