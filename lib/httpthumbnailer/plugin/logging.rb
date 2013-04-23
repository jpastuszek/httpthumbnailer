require 'logger'

class ExtendedLogger
	@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

	def initialize(logger, class_name)
		@logger = logger
		@class_name = class_name
	end

	def method_missing(name, *args, &block)
		if @@levels.include? name
			message = args.map do |arg|
				if arg.is_a? Exception
					"#{arg.class.name}: #{arg.message}\n#{arg.backtrace.join("\n")}"
				else
					arg.to_s
				end
			end.join(': ')

			@logger.send(name, "[#{@class_name}] " + message, &block)
		else
			@logger.send(name, *args, &block)
		end
	end
end

module Plugin
	module Logging
		def log
			return @logger if @logger
			@logger = logger_for(self.class)
		end

		def logger_for(class_obj)
			logger = env['app.logger'] || env['rack.logger'] || raise(RuntimeError, 'request logger not set')
			ExtendedLogger.new(logger, class_obj.name)
		end
	end
end

