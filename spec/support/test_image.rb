require 'pathname'

module TestImage
	def self.io(name)
		File.open(Pathname.new(__FILE__).dirname + name)
	end
end

def show_blob(blob)
	t = Tempfile.new('blob')
	t.write(blob)
	t.close
	`display '#{t.path}'`
	#pid = Process.spawn "display '#{t.path}'"
	#Process.detach pid
end
