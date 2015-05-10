require_relative 'spec_helper'
require 'httpthumbnailer/ownership'

class Image
	include Ownership

	def destroy!
		@destoryed and fail 'destroying already destroyed!'
		@destoryed = true
	end

	def destoryed?
		@destoryed
	end
end

describe 'image ownership' do
	subject do
		Image.new
	end

	describe '#own' do
		it 'should take ownership of new image and yield it' do
			subject.own do |image|
				subject.should be image
				image.should be_owned
			end
		end
		it 'should destory new image returned by the block' do
			new_image = Image.new
			subject.own do |image|
				new_image
			end
			subject.should be_destoryed
			new_image.should be_destoryed
		end
		it 'should return nil' do
			subject.own do |image|
			end.should be_nil
		end

		context 'on image that was not moved' do
			it 'should end up with not destoryed image' do
				subject.own do |image|
					image.borrow do |borrowed|
					end
					image.should_not be_destoryed
				end
			end
			it 'should destory the image' do
				subject.own do |image|
					image.borrow do |borrowed|
					end
				end
				subject.should be_destoryed
			end
		end
		context 'when image was moved' do
			it 'should end up with destoryed image' do
				subject.own do |image|
					image.move do |moved|
					end
					image.should be_destoryed
					image
				end
				subject.should be_destoryed
			end
		end
	end

	describe '#borrow' do
		it 'should yield image' do
			subject.own do |image|
				subject.borrow do |borrowed|
					image.should be borrowed
				end
			end
		end
		it 'should not take ownership image' do
			subject.own do |image|
				image.should be_owned
				subject.borrow do |borrowed|
					borrowed.should_not be_owned
				end
				image.should be_owned
			end
		end
		context 'when new image was returned by the block' do
			it 'should return new image' do
				new_image = Image.new

				subject.own do |image|
					ret = subject.borrow do |borrowed|
						new_image
					end
					ret.should be new_image
					ret.should_not be_owned
				end
			end
			it 'should not destroy image' do
				new_image = Image.new

				subject.own do |image|
					ret = subject.borrow do |borrowed|
						borrowed.should_not be_destoryed
						new_image
					end
					ret.should_not be_destoryed
					image.should_not be_destoryed
				end
				subject.should be_destoryed
			end
		end
		context 'when other kind of object was returned by the block' do
			it 'should return that object' do
				subject.own do |image|
					ret = subject.borrow do |borrowed|
						1
					end
					ret.should be 1
					image.should be_owned
				end
				subject.should be_destoryed
			end
			it 'should not destroy image' do
				subject.own do |image|
					subject.borrow do |borrowed|
						borrowed.should_not be_destoryed
						1
					end
					image.should_not be_destoryed
				end
				subject.should be_destoryed
			end
		end
	end

	describe '#move' do
		it 'should yield image' do
			subject.own do |image|
				image.move do |moved|
					image.should be moved
				end
			end
		end
		it 'should transfer ownership' do
			subject.own do |image|
				image.should be_owned
				image.move do |moved|
					moved.should be_owned
				end
				image.should_not be_owned
			end
		end
		context 'with borrowed image' do
			it 'should raise error' do
				subject.own do |image|
					image.borrow do |borrowed|
						expect {
							borrowed.move do |image|
							end
						}.to raise_error Ownership::MovingBorrowedError
					end
				end
			end
		end
		context 'when new image was returned by the block' do
			it 'should return new image' do
				new_image = Image.new

				subject.own do |image|
					ret = image.move do |moved|
						new_image
					end
					ret.should be new_image
				end
			end
			it 'should destory image it was moving' do
				new_image = Image.new

				subject.own do |image|
					ret = image.move do |moved|
						new_image
					end
					ret.should_not be_destoryed
					image.should be_destoryed
				end
			end
		end
		describe 'moving out' do
			context 'when self was returned' do
				it 'should not destroy the image and yield the ownership' do
					subject.own do |image|
						image.should be_owned
						image.move do |moved|
							moved.should be_owned
							moved
						end
						image.should_not be_owned
						subject.should_not be_destoryed
					end
					subject.should_not be_destoryed
				end
				it 'should return the image' do
					subject.own do |image|
						ret = image.move do |moved|
							moved
						end
						ret.should be image
					end
					subject.should_not be_destoryed
				end
			end
		end
		context 'when other kinde of object was returned by the block' do
			it 'should return that object' do
				subject.own do |image|
					ret = subject.move do |borrowed|
						1
					end
					ret.should be 1
				end
			end
			it 'should destory image it was moving' do
				subject.own do |image|
					image.move do |moved|
						1
					end
					image.should be_destoryed
				end
			end
		end
	end

	describe '#replace' do
		it 'should take ownership of new image' do
			subject.replace do |image|
				subject.should be_owned
			end
			subject.should be_destoryed
		end
		it 'should borrow borrowed image' do
			subject.own do |image|
				image.borrow do |borrowed|
					borrowed.should_not be_owned
					borrowed.replace do |replaced|
						replaced.should_not be_owned
					end
				end
			end
		end
		it 'should move owned image' do
			subject.own do |image|
				image.move do |moved|
					moved.should be_owned
					moved.replace do |replaced|
						replaced.should be_owned
					end
				end
			end
		end

		describe 'contitional return' do
			context 'when new image is returned' do
				context 'and the image was owned' do
					it 'should destory the image' do
						new_image = Image.new
						subject.own do |image|
							ret = image.replace do |replaced|
								new_image
							end
							ret.should_not be_destoryed
							image.should be_destoryed
						end
					end
					it 'should return new image' do
						new_image = Image.new
						subject.own do |image|
							ret = image.replace do |replaced|
								new_image
							end
							ret.should be new_image
						end
					end
				end
				context 'and the image was not owned' do
					it 'should not destory the image' do
						new_image = Image.new
						subject.own do |image|
							image.borrow do |borrowed|
								ret = borrowed.replace do |replaced|
									new_image
								end
								ret.should_not be_destoryed
								image.should_not be_destoryed
							end
						end
					end
					it 'should return new image' do
						new_image = Image.new
						subject.own do |image|
							image.borrow do |borrowed|
								ret = borrowed.replace do |replaced|
									new_image
								end
								ret.should be new_image
							end
						end
					end
				end
			end
			context 'when self is returend' do
				context 'and the image was owned' do
					it 'should not destory the image' do
						subject.own do |image|
							ret = image.replace do |replaced|
								replaced
							end
							ret.should_not be_destoryed
							image.should_not be_destoryed
						end
					end
					it 'should return the image' do
						subject.own do |image|
							ret = image.replace do |replaced|
								replaced
							end
							ret.should be image
						end
					end
				end
				context 'and the image was not owned' do
					it 'should not destory the image' do
						subject.own do |image|
							image.borrow do |borrowed|
								ret = borrowed.replace do |replaced|
									replaced
								end
								ret.should_not be_destoryed
								borrowed.should_not be_destoryed
							end
							image.should_not be_destoryed
						end
					end
					it 'should return new image' do
						subject.own do |image|
							image.borrow do |borrowed|
								ret = borrowed.replace do |replaced|
									replaced
								end
								ret.should be image
							end
						end
					end
				end
			end
		end

		context 'image is owned' do
			context 'new image is returned' do
				it 'should return new image' do
					new_image = Image.new
					subject.own do |image|
						ret = image.replace do |moved|
							moved.should be_owned
							new_image
						end
						ret.should be new_image
					end
				end
				it 'should move ownership of the image' do
					new_image = Image.new
					subject.own do |image|
						image.should be_owned
						image.replace do |moved|
							moved.should be_owned
							new_image
						end
						image.should_not be_owned
						image.should be_destoryed
					end
					subject.should be_destoryed
				end
			end
		end
	end

	describe 'image after borrow' do
		it 'should not be destoryed' do
			subject.own do |image|
				image.borrow do |borrowed|
					borrowed.should_not be_destoryed
				end
				image.should_not be_destoryed
			end
			subject.should be_destoryed
		end
		it 'can be borrowed' do
			subject.own do |image|
				image.borrow do |borrowed|
				end
				image.borrow do |borrowed2|
					borrowed2.should be subject
				end
			end
		end
		it 'can be mvoed' do
			subject.own do |image|
				image.borrow do |borrowed|
				end
				image.move do |moved|
					moved.should be subject
				end
			end
		end
	end

	describe 'image after move' do
		it 'should be destoryed' do
			subject.own do |image|
				image.move do |moved|
					moved.should_not be_destoryed
				end
				image.should be_destoryed
			end
			subject.should be_destoryed
		end
		it '#borrow should raise error' do
			subject.own do |image|
				image.move do |moved|
				end
				expect {
					image.borrow do |image|
					end
				}.to raise_error Ownership::BorrowingAfterMoveError
			end
		end
		it '#move should raise error' do
			subject.own do |image|
				image.move do |moved|
				end
				expect {
					image.move do |image|
					end
				}.to raise_error Ownership::MovingAfterMoveError
			end
		end
	end

	describe 'exception safety' do
		pending
	end
end

