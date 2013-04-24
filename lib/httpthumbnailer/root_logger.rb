require 'logger'

class RootLogger < Logger
	class ClassLogger
		@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

		def initialize(logger, class_obj)
			@logger = logger
			@class_name = class_obj.name
		end

		def respond_to?(method)
			@logger.respond_to? method
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

	def logger_for(class_obj)
		ClassLogger.new(self, class_obj)
	end
end

