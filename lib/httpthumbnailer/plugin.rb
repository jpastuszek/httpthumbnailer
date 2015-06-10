class PluginContext
	include ClassLogging
	PluginArgumentError = Class.new ArgumentError
	include PerfStats

	attr_reader :thumbnailing_methods
	attr_reader :edits

	def initialize(&block)
		@thumbnailing_methods = []
		@edits = []
		instance_eval(&block)
	end

	def self.from_file(file)
		self.new do
			instance_eval file.read, file.to_s
		end
	end

	def thumbnailing_method(name, &block)
		name.kind_of? String or fail "thumbnailing method name must ba a string; got: #{name.class.name}"
		block.kind_of? Proc or fail "thumbnailing method '#{name}' needs to provide an implementation; got: #{name.class.name}"
		@thumbnailing_methods << [name, block]
	end

	def edit(name, &block)
		name.kind_of? String or fail "edit name must ba a string; got: #{name.class.name}"
		block.kind_of? Proc or fail "edit '#{name}' needs to provide an implementation; got: #{name.class.name}"
		@edits << [name, block]
	end

	def with_default(arg, default = nil)
		return default if arg.nil? or arg == ''
		arg
	end

	# static helpers
	def int!(name, arg, default = nil)
		value = with_default(arg, default) or raise PluginArgumentError, "expected argument '#{name}' to be an integer but got no value"
		begin
			Integer(value)
		rescue ArgumentError
			raise PluginArgumentError, "expected argument '#{name}' to be an integer, got: #{arg.inspect}"
		end
	end

	def uint!(name, arg, default = nil)
		ret = int!(name, arg, default)
	 	ret < 0 and raise PluginArgumentError, "expected argument '#{name}' to be an unsigned integer, got negative value: #{arg}"
		ret
	end

	def float!(name, arg, default = nil)
		value = with_default(arg, default) or raise PluginArgumentError, "expected argument '#{name}' to be a float but got no value"
		begin
			Float(value)
		rescue ArgumentError
			raise PluginArgumentError, "expected argument '#{name}' to be a float, got: #{arg}"
		end
	end

	def ufloat!(name, arg, default = nil)
		ret = float!(name, arg, default)
		ret < 0 and raise PluginArgumentError, "expected argument '#{name}' to be an unsigned float, got negative value: #{arg}"
		ret
	end

	def offset_to_center(x, y, w, h)
		[x + w / 2, y + h / 2]
	end

	def center_to_offset(center_x, center_y, w, h)
		[center_x - w / 2, center_y - h / 2]
	end

	def normalize_region(x, y, width, height)
		x = 0.0 if x < 0
		y = 0.0 if y < 0
		width = 1.0 - x if width + x > 1
		height = 1.0 - y if height + y > 1
		width = Float::EPSILON if width < 0
		height = Float::EPSILON if height < 0
		[x, y, width, height]
	end
end

