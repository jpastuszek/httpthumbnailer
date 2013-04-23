require_relative 'spec_helper'

require 'httpthumbnailer/plugin/logging'
require 'cuba'
require 'stringio'

class TestLoggerMiddleware
	def initialize(app)
		@app = app
	end

	def call(env)
		@@log_out = StringIO.new
		env['app.logger'] = Logger.new(@@log_out)
		@app.call(env)
	end

	def self.log_out
		@@log_out
	end
end

describe 'logging', type: :request do

	TestApp = Class.new(Cuba)
	TestApp.plugin Plugin::Logging
	TestApp.use TestLoggerMiddleware
	TestApp.define do
		on 'log', 'info', :message do |message|
			log.info URI.decode(message)
		end

		on 'log', 'warn', :message do |message|
			log.warn URI.decode(message)
		end

		on 'log', 'error', :message do |message|
			log.error URI.decode(message)
		end

		on 'log', 'class', :class, :message do |class_name, message|
			logger_for(eval(class_name)).info URI.decode(message)
		end

		on 'log', 'exception', :message, :error_message do |message, error_message|
			begin
				fail URI.decode(error_message)
			rescue => error
				log.info URI.decode(message), error
			end
		end

		on true do
			fail 'unhandled request'
		end
	end
	Capybara.app = TestApp

	subject do
		TestApp
	end

	it 'should log to given logger' do
		visit("/log/info/#{URI.encode('hello world')}")

		TestLoggerMiddleware.log_out.string.should include 'INFO'
		TestLoggerMiddleware.log_out.string.should include 'hello world'
	end

	describe 'support for different logging levels' do
		it 'should log info' do
			visit("/log/info/#{URI.encode('hello world')}")

			TestLoggerMiddleware.log_out.string.should include 'INFO'
		end

		it 'should log warn' do
			visit("/log/warn/#{URI.encode('hello world')}")

			TestLoggerMiddleware.log_out.string.should include 'WARN'
		end

		it 'should log error' do
			visit("/log/error/#{URI.encode('hello world')}")

			TestLoggerMiddleware.log_out.string.should include 'ERROR'
		end
	end

	it 'should report class name' do
		visit("/log/info/#{URI.encode('hello world')}")

		TestLoggerMiddleware.log_out.string.should include '[TestApp]'
	end

	it 'should allow getting logger for given class' do
		visit("/log/class/String/#{URI.encode('hello world')}")

		TestLoggerMiddleware.log_out.string.should include '[String]'
	end

	it 'should log exceptions' do
		visit("/log/exception/#{URI.encode('hello world')}/#{URI.encode('bad luck')}")

		TestLoggerMiddleware.log_out.string.should include 'hello world: RuntimeError: bad luck'
	end
end

