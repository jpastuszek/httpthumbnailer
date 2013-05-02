require_relative 'spec_helper'

require 'httpthumbnailer/root_logger'
require 'stringio'

describe  do
	let! :log_out do
		StringIO.new
	end

	subject do
		RootLogger.new(log_out)
	end

	it 'should log to given logger' do
		subject.info 'hello world'
		log_out.string.should include 'INFO'
		log_out.string.should include 'hello world'
	end

	describe 'support for different logging levels' do
		it 'should log info' do
			subject.info 'hello world'
			log_out.string.should include 'INFO'
		end

		it 'should log warn' do
			subject.warn 'hello world'
			log_out.string.should include 'WARN'
		end

		it 'should log error' do
			subject.error 'hello world'
			log_out.string.should include 'ERROR'
		end
	end

	describe 'class logger' do
		it 'should report class name' do
			TestApp = Class.new
			subject.logger_for(TestApp).info 'hello world'
			log_out.string.should include 'TestApp'

			subject.logger_for(String).info 'hello world'
			log_out.string.should include 'String'
		end

		it 'should log exceptions' do
			begin
				raise RuntimeError, 'bad luck'
			rescue => error
				subject.logger_for(String).error 'hello world', error
			end
			log_out.string.should include 'hello world: RuntimeError: bad luck'
		end
	end
end

