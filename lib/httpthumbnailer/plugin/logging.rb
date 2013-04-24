module Plugin
	module Logging
		def log
			return @logger if @logger
			@logger = self.class.logger_for(self.class)
		end
	end
end

