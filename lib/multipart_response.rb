class MultipartResponse
	class NoBoundaryFoundInContentTypeError < ArgumentError
		def initialize(content_type_header, exception)
			super("Content-Type header of '#{content_type_header}' has no boundary defined: #{exception.class.name}: #{exception}")
		end
	end

	class Part
		def initialize(data)
			if data.include?("\r\n\r\n")
				headers, *body = *data.split("\r\n\r\n")
				@headers = Hash[headers.split("\r\n").map{|h| h.split(/: ?/)}]
				@body = body.join("\r\n\r\n")
			else
				@headers = {'Content-Type' => 'text/plain'}
				@body = data
			end
		end

		attr_reader :headers, :body
		alias :header :headers
	end

	def initialize(content_type_header, body)
		@boundary = begin
			content_type_header.split(';').map{|e| e.strip}.select{|e| e =~ /^boundary=/}.first.match(/^boundary="(.*)"/)[1]
		rescue => e
			raise NoBoundaryFoundInContentTypeError.new(content_type_header, e)
		end

		body, epilogue = *body.split("--#{@boundary}--")
		preamble, *parts = *body.split("--#{@boundary}")
		
		@preamble = preamble.sub(/\r\n$/m, '')
		@preamble = nil if @preamble.empty?

		@epilogue = epilogue.sub(/^\r\n/m, '') if epilogue

		@parts = parts.map{|p| p.sub(/^\r\n/m, '').sub(/\r\n$/m, '')}.map{|p| Part.new(p)}
	end

	attr_reader :boundary, :preamble, :parts, :epilogue
	alias :part :parts
end

