require 'pathname'

module TestImage
	def self.io(name)
		File.open(Pathname.new(__FILE__).dirname + name)
	end
end
