module Plugin
	module ResponseHelpers
		def write_plain(code, msg)
			res.status = code
			res["Content-Type"] = "text/plain"
			res.write msg.gsub("\n", "\r\n") + "\r\n"
		end

		def write_error(code, error)
			msg = "Error: #{error}"
			log.info "Sending #{code} error response: #{msg}"
			write_plain code, msg
		end
	end
end

