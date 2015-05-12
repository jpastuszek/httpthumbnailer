require 'forwardable'
require 'httpthumbnailer/plugin'
require_relative 'thumbnailer/service'

module Plugin
	module Thumbnailer
		include ClassLogging

		class UnsupportedMethodError < ArgumentError
			def initialize(method)
				super("thumbnail method '#{method}' is not supported")
			end
		end

		class UnsupportedEditError < ArgumentError
			def initialize(name)
				super("no edit with name '#{name}' is supported")
			end
		end

		class UnsupportedMediaTypeError < ArgumentError
			def initialize(error)
				super("unsupported media type: #{error}")
			end
		end

		class ImageTooLargeError < ArgumentError
			def initialize(error)
				super("image too large: #{error}")
			end
		end

		class ZeroSizedImageError < ArgumentError
			def initialize(width, height)
				super("at least one image dimension is zero: #{width}x#{height}")
			end
		end

		class InvalidColorNameError < ArgumentError
			def initialize(color)
				super("invalid color name: #{color}")
			end
		end

		class ThumbnailArgumentError < ArgumentError
			def initialize(method, msg)
				super("error while thumbnailing with method '#{method}': #{msg}")
			end
		end

		class EditArgumentError < ArgumentError
			def initialize(name, msg)
				super("error while applying edit '#{name}': #{msg}")
			end
		end

		def self.setup(app)
			Service.logger = app.logger_for(Service)

			@@service = Service.new(
				limit_memory: app.settings[:limit_memory],
				limit_map: app.settings[:limit_map],
				limit_disk: app.settings[:limit_disk]
			)
			@@service.setup_built_in_plugins
		end

		def self.setup_plugin_from_file(file)
			log.info("loading plugin from: #{file}")
			@@service.load_plugin(PluginContext.from_file(file))
		end

		def thumbnailer
			@@service
		end
	end
end

