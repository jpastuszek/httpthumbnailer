class ErrorReporter < Controler
	self.define do
		on error Rack::UnhandledRequest::UnhandledRequestError do |error|
			write_error 404, error
		end

		on error Plugin::Thumbnailer::UnsupportedMediaTypeError do |error|
			write_error 415, error
		end

		on error(
			Plugin::Thumbnailer::ImageTooLargeError,
			MemoryLimit::MemoryLimitedExceededError
		)	do |error|
			write_error 413, error
		end

		on error(
			ThumbnailSpec::BadThubnailSpecError,
			Plugin::Thumbnailer::ZeroSizedImageError,
			Plugin::Thumbnailer::UnsupportedMethodError
		) do |error|
			write_error 400, error
		end

		on error StandardError do |error|
			log.error "unhandled error while processing request: #{env['REQUEST_METHOD']} #{env['SCRIPT_NAME']}[#{env["PATH_INFO"]}]", error
			log.debug {
				out = StringIO.new
				PP::pp(env, out, 200)
				"Request: \n" + out.string
			}

			write_error 500, error
		end
	end
end

