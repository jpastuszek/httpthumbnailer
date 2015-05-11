require_relative 'spec_helper'
require 'httpthumbnailer/ownership'

class TestObject
	include Ownership

	def destroy!
		@destoryed and fail 'destroying already destroyed!'
		@destoryed = true
	end

	def destoryed?
		@destoryed
	end
end

describe 'object ownership' do
	subject do
		TestObject.new
	end

	describe '#get' do
		it 'should yield object' do
			subject.get do |object|
				object.should be subject
			end
		end
		it 'should transfer ownership to yielded object' do
			subject.get do |object|
				object.should be_owned
				object.get do |moved|
					moved.should be_owned
				end
				object.should_not be_owned
			end
			subject.should_not be_owned
		end

		context 'when new object was returned by the block' do
			it 'should return new object' do
				new_object = TestObject.new

				ret = subject.get do |object|
					ret = object.get do |moved|
						new_object
					end
					ret.should be new_object
					ret
				end
				ret.should be new_object
			end
			it 'should destory object it was moving' do
				new_object = TestObject.new

				subject.get do |object|
					ret = object.get do |moved|
						new_object
					end
					ret.should_not be_destoryed
					object.should be_destoryed
					ret
				end
				subject.should be_destoryed
			end
		end

		describe 'putting back' do
			context 'when self was returned' do
				it 'should return the object' do
					ret = subject.get do |object|
						ret = object.get do |moved|
							moved
						end
						ret.should be object
						ret
					end
					ret.should be subject
				end
				it 'give up the ownership' do
					subject.get do |object|
						object.should be_owned
						object.get do |moved|
							moved.should be_owned
							moved
						end
						object.should_not be_owned
					end
					subject.should_not be_owned
				end
				it 'should not destroy the object' do
					subject.get do |object|
						ret = object.get do |moved|
							moved
						end
						object.should_not be_destoryed
						ret
					end
					subject.should_not be_destoryed
				end
			end
			context 'when nil was returned' do
				it 'should return the object' do
					ret = subject.get do |object|
						ret = object.get do |moved|
							nil
						end
						ret.should be object
						ret
					end
					ret.should be subject
				end
				it 'give up the ownership' do
					subject.get do |object|
						object.should be_owned
						object.get do |moved|
							moved.should be_owned
							nil
						end
						object.should_not be_owned
					end
					subject.should_not be_owned
				end
				it 'should not destroy the object' do
					subject.get do |object|
						ret = object.get do |moved|
							nil
						end
						object.should_not be_destoryed
						ret
					end
					subject.should_not be_destoryed
				end
			end
		end
		context 'when other kinde of object was returned by the block' do
			it 'should return that object' do
				subject.get do |object|
					ret = subject.get do |borrowed|
						1
					end
					ret.should be 1
				end
			end
			it 'should destory object it was moving' do
				subject.get do |object|
					object.get do |moved|
						1
					end
					object.should be_destoryed
				end
			end
		end
		it 'should borrow borrowed object' do
			subject.get do |object|
				object.borrow do |borrowed|
					borrowed.should be_borrowed
					borrowed.get do |replaced|
						replaced.should be_borrowed
					end
				end
			end
		end

		describe 'after get' do
			it '#borrow should raise error' do
				subject.get do |object|
					object.get do |moved|
						1
					end
					expect {
						object.borrow do |object|
						end
					}.to raise_error Ownership::BorrowingDestoryedError
				end
			end
			it '#get should raise error' do
				subject.get do |object|
					object.get do |moved|
						1
					end
					expect {
						object.get do |object|
						end
					}.to raise_error Ownership::UseDestroyedError
				end
			end
		end
	end

	describe '#borrow' do
		it 'should yield object' do
			subject.get do |object|
				subject.borrow do |borrowed|
					object.should be borrowed
				end
			end
		end
		it 'should not take ownership of yielded object' do
			subject.get do |object|
				object.should be_owned
				object.should_not be_borrowed
				subject.borrow do |borrowed|
					borrowed.should be_owned
					borrowed.should be_borrowed
				end
				object.should be_owned
			end
		end
		it 'should not destroy the object' do
			subject.get do |object|
				subject.borrow do |borrowed|
					1
				end
				object.should_not be_destoryed
				subject.borrow do |borrowed|
					borrowed
				end
				object.should_not be_destoryed
				subject.borrow do |borrowed|
					nil
				end
				object.should_not be_destoryed
				true
			end
			subject.should be_destoryed
		end
		it 'should return any object' do
			subject.get do |object|
				ret = subject.borrow do |borrowed|
					1
				end
				ret.should be 1
				ret = subject.borrow do |borrowed|
					borrowed
				end
				ret.should be object
				ret = subject.borrow do |borrowed|
					nil
				end
				ret.should be nil
			end
		end

		context 'after borrow' do
			it 'should allow borrowing' do
				subject.get do |object|
					subject.borrow do |borrowed|
						borrowed.should be object
					end
					subject.borrow do |borrowed|
						borrowed.should be object
					end
				end
			end
			it 'should allow getting' do
				subject.get do |object|
					object.borrow do |borrowed|
					end
					object.get do |moved|
						moved.should be subject
					end
				end
			end
		end
	end

	describe 'exception safety' do
		context 'when exception was thrown' do
			it 'should destroy owned object' do
				expect {
					subject.get do |object|
						raise 'test'
					end
				}.to raise_error RuntimeError, 'test'
				subject.should be_destoryed
			end

			it 'should destroy owned and then borrowed object' do
				expect {
					subject.get do |object|
						subject.borrow do |object|
							raise 'test'
						end
					end
				}.to raise_error RuntimeError, 'test'
				subject.should be_destoryed
			end

			it 'should destroy owned and then moved object' do
				expect {
					subject.get do |object|
						subject.get do |object|
							raise 'test'
						end
					end
				}.to raise_error RuntimeError, 'test'
				subject.should be_destoryed
			end
		end
	end
end

