require 'securerandom'

module Plugin
	module ResponseHelpers
		def write_plain(code, msg)
			res.status = code
			res["Content-Type"] = "text/plain"
			res.write msg.gsub("\n", "\r\n") + "\r\n"
		end

		def write_error(code, error)
			msg = "Error: #{error}"
			log.warn "sending #{code} error response: #{msg}"
			write_plain code, msg
		end

		# Multipart
		def write_preamble(code, headers = {})
			res.status = code
			@boundary = SecureRandom.uuid
			res["Content-Type"] = "multipart/mixed; boundary=\"#{@boundary}\""
			headers.each do |key, value|
				res[key] = value
			end
		end

		def write_part(content_type, body)
			res.write "--#{@boundary}\r\n"
			res.write "Content-Type: #{content_type}\r\n\r\n"
			res.write body
			res.write "\r\n"
		end

		def write_plain_part(msg)
			write_part 'text/plain', msg.gsub("\n", "\r\n")
		end

		def write_error_part(error)
			msg = "Error: #{error}"
			log.warn "sending error in multipart response part: #{msg}"
			write_plain_part msg
		end

		def write_epilogue
			res.write "--#{@boundary}\r\n"
		end
	end
end

