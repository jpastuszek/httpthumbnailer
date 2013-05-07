require 'securerandom'

module Plugin
	module ResponseHelpers
		extend Stats
		def_stats(
			:total_write_multipart,
			:total_write, 
			:total_write_part, 
			:total_write_error, 
			:total_write_error_part
		)

		def write(code, content_type, body)
			res.status = code
			res["Content-Type"] = content_type
			ResponseHelpers.stats.incr_total_write
			res.write body
		end

		def write_plain(code, msg)
			write code, 'text/plain', msg.gsub("\n", "\r\n") + "\r\n"
		end

		def write_error(code, error)
			msg = "Error: #{error}"
			log.warn "sending #{code} error response: #{msg}"
			ResponseHelpers.stats.incr_total_write_error
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
			ResponseHelpers.stats.incr_total_write_multipart
		end

		def write_part(content_type, body)
			res.write "--#{@boundary}\r\n"
			res.write "Content-Type: #{content_type}\r\n\r\n"
			ResponseHelpers.stats.incr_total_write_part
			res.write body
			res.write "\r\n"
		end

		def write_plain_part(msg)
			write_part 'text/plain', msg.gsub("\n", "\r\n")
		end

		def write_error_part(error)
			msg = "Error: #{error}"
			log.warn "sending error in multipart response part: #{msg}"
			ResponseHelpers.stats.incr_total_write_error_part
			write_plain_part msg
		end

		def write_epilogue
			res.write "--#{@boundary}--\r\n"
		end
	end
end

