class PluginContext
	attr_reader :processing_methods

	def initialize(file)
		@processing_methods = []

		instance_eval file.read, file.to_s
	end

	def processing_method(name, &block)
		name.kind_of? String or fail "processing method name must ba a string; got: #{name.class.name}"
		block.kind_of? Proc or fail "processing method '#{name}' needs to provide an implementation; got: #{name.class.name}"
		@processing_methods << [name, block]
	end
end

