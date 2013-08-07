require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end


require 'rspec/expectations'
require 'multipart_parser/reader'
require 'daemon'
require 'timeout'
require 'httpclient'
require "open3"
require "thread"
require 'RMagick'
require 'json'

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

def http_client
	client = HTTPClient.new
	#client.debug_dev = STDOUT
	client
end

@@running_cmd = {}
def start_server(cmd, pid_file, log_file, test_url)
	if @@running_cmd[pid_file]
		return if @@running_cmd[pid_file] == cmd
		stop_server(pid_file) 
	end

	fork do
		Daemon.daemonize(pid_file, log_file)
		log_file = Pathname.new(log_file)
		log_file.truncate(0) if log_file.exist?
		exec(cmd)
	end

	@@running_cmd[pid_file] = cmd

	ppid = Process.pid
	at_exit do
		stop_server(pid_file) if Process.pid == ppid
	end

	Timeout.timeout(6) do
		begin
			http_client.get_content test_url
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end
end

def stop_server(pid_file)
	pid_file = Pathname.new(pid_file)
	return unless pid_file.exist?

	STDERR.puts http_client.get_content("http://localhost:3100/stats")
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

After do |scenario|
	step 'there should be no leaked images'
	step 'there should be maximum 3 images loaded during single request'
end

