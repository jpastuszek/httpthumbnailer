class PluginContext
	attr_reader :thumbnailing_methods

	def initialize(file)
		@thumbnailing_methods = []

		instance_eval file.read, file.to_s
	end

	def thumbnailing_method(name, &block)
		name.kind_of? String or fail "thumbnailing method name must ba a string; got: #{name.class.name}"
		block.kind_of? Proc or fail "thumbnailing method '#{name}' needs to provide an implementation; got: #{name.class.name}"
		@thumbnailing_methods << [name, block]
	end

	# static helpers

	def offset_to_center(x, y, w, h)
		[x + w / 2, y + h / 2]
	end

	def center_to_offset(center_x, center_y, w, h)
		[center_x - w / 2, center_y - h / 2]
	end
end

