require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'rspec/expectations'
require 'daemon'
require 'timeout'
require 'httpclient'
require 'httpthumbnailer/multipart_response'
require "open3"
require "thread"

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

def server_get(uri)
	HTTPClient.new.get_content("http://localhost:3333#{uri}")
end

def server_request(method, uri, query = nil, body = nil)
	HTTPClient.new.request(method, "http://localhost:3333#{uri}", query, body)
end

def server_start
	File.exist?("/tmp/httpthumbnailer.pid") and server_stop
	fork do
		Daemon.daemonize("/tmp/httpthumbnailer.pid", support_dir + 'server.log')
		exec("bundle exec #{script('httpthumbnailer')} -p 3333")
	end

	Timeout.timeout(10) do
		begin
			server_get '/'
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end
end

def server_stop
	File.open("/tmp/httpthumbnailer.pid") do |pidf|
		pid = pidf.read

		Timeout.timeout(10) do
			begin
				loop do
					ret = Process.kill("TERM", pid.strip.to_i)
					sleep 0.1
				end
			rescue Errno::ESRCH
			end
		end
	end
end

def part_no(part)
	case part
		when 'first' then 0
		when 'second' then 1
		when 'third' then 2
		else fail "add more parts?"
	end
end
