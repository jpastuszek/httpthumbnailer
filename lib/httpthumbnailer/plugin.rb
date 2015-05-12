class PluginContext
	PluginArgumentError = Class.new ArgumentError

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

	# static helpers
	def float!(name, arg, default = nil)
		value = arg
		value ||= default or raise PluginArgumentError, "expected argument '#{name}' to be a float but got no value"
		begin
			Float(value)
		rescue
			raise PluginArgumentError, "expected argument '#{name}' to be a float, got: #{arg}"
		end
	end

	def offset_to_center(x, y, w, h)
		[x + w / 2, y + h / 2]
	end

	def center_to_offset(center_x, center_y, w, h)
		[center_x - w / 2, center_y - h / 2]
	end
end

