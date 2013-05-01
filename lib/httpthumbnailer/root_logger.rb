require 'logger'

class RootLogger < Logger
	class ClassLogger
		@@levels = [:debug, :info, :warn, :error, :fatal, :unknown]

		def initialize(logger, class_obj)
			@logger = logger
			self.progname = class_obj.name

			self.formatter = proc do |severity, datetime, progname, msg|
				"[#{datetime.utc.strftime "%Y-%m-%d %H:%M:%S.%6N %Z"}] [#{$$} #{progname}] #{severity}: #{msg}\n"
			end
		end

		def respond_to?(method)
			@logger.respond_to? method
		end

		def method_missing(name, *args, &block)
			if @@levels.include? name
				message = if block_given?
					self.progname
				else
					args.map do |arg|
						if arg.is_a? Exception
							"#{arg.class.name}: #{arg.message}\n#{arg.backtrace.join("\n")}"
						else
							arg.to_s
						end
					end.join(': ')
				end

				@logger.send(name, message, &block)
			else
				@logger.send(name, *args, &block)
			end
		end
	end

	def logger_for(class_obj)
		ClassLogger.new(self, class_obj)
	end
end

module ClassLogging
	def logger=(logger)
		@@logger = logger
	end

	def log
		return @@logger if defined? @@logger
		@@logger = Logger.new(STDERR)
	end

	def self.included(class_obj)
		class_obj.extend self
	end
end

