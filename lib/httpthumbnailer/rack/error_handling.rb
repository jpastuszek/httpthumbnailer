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
				#log.error "Error while processing request: #{env['REQUEST_METHOD']} #{env['SCRIPT_NAME']}[#{env["PATH_INFO"]}]", error
				#log.debug {
				#	out = StringIO.new
				#	PP::pp(env, out, 200)
				#	"Request: \n" + out.string
				#}

				begin
					# reset env to original since it could have been changed
					env.clear
					env.merge!(orig_env)

					# set error so app can handle it
					env["ERROR"] = error

					return @app.call(env)
				rescue => fatal
					#log.fatal "Error while handling error #{env["ERROR"]}: #{env['SCRIPT_NAME']}[#{env["PATH_INFO"]}]", fatal
					raise 
				end
			end
		end
	end
end

