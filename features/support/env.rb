require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end


require 'rspec/expectations'
require 'daemon'
require 'timeout'
require 'httpclient'
require "open3"
require "thread"
require 'RMagick'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'multipart_response'

def gem_dir
		Pathname.new(__FILE__).dirname + '..' + '..'
end

def features_dir
		gem_dir + 'features'
end

def support_dir
		features_dir + 'support'
end

def script(file)
		gem_dir + 'bin' + file
end

def part_no(part)
	case part
		when 'first' then 0
		when 'second' then 1
		when 'third' then 2
		else fail "add more parts?"
	end
end

def get(url)
	HTTPClient.new.get_content(url)
end

def start_server(cmd, pid_file, log_file, test_url)
	pid_file = Pathname.new(pid_file)
	return if pid_file.exist?

	Pathname.new(log_file).truncate(0)
	fork do
		Daemon.daemonize(pid_file, log_file)
		exec(cmd)
	end
	Process.wait

	ppid = Process.pid
	at_exit do
		stop_server(pid_file) if Process.pid == ppid
	end

	Timeout.timeout(20) do
		begin
			get test_url
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end
end

def stop_server(pid_file)
	pid_file = Pathname.new(pid_file)
	return unless pid_file.exist?

	STDERR.puts HTTPClient.new.get_content("http://localhost:3100/stats")
	pid = pid_file.read.strip.to_i

	Timeout.timeout(20) do
		begin
			loop do
				Process.kill("TERM", pid)
				sleep 0.1
			end
		rescue Errno::ESRCH
			pid_file.unlink
		end
	end
end

at_exit do
	stop_server '/tmp/httpthumbnailer.pid'
end

After do |scenario|
	step 'there should be no leaked images'
	step 'there should be maximum 3 images loaded during single request'
end

