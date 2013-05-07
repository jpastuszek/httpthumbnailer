class MultipartResponse
	class NoBoundaryFoundInContentTypeError < ArgumentError
		def initialize(content_type_header, exception)
			super("Content-Type header of '#{content_type_header}' has no boundary defined: #{exception.class.name}: #{exception}")
		end
	end

	class MissingEpilogueError < ArgumentError
		def initialize
			super("no epilogue was found in the response")
		end
	end

	class Part
		def initialize(data)
			if data.include?("\r\n\r\n")
				headers, *body = *data.split("\r\n\r\n", 2)
				@headers = Hash[headers.split("\r\n").map{|h| h.split(/: ?/)}]
				@body = body.last
			else
				@headers = {}
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

		body, epilogue = *body.split("--#{@boundary}--", 2)
		preamble, *parts = *body.split("--#{@boundary}")
		
		@preamble = preamble.sub(/\r\n$/m, '')
		@preamble = nil if @preamble.empty?

		raise MissingEpilogueError unless epilogue
		@epilogue = epilogue.sub(/^\r\n/m, '')

		@parts = parts.map{|p| p.sub(/^\r\n/m, '').sub(/\r\n$/m, '')}.map{|p| Part.new(p)}
	end

	attr_reader :boundary, :preamble, :parts, :epilogue
	alias :part :parts
end

