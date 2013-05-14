require_relative 'spec_helper'
require 'unicorn-cuba-base'
require 'httpthumbnailer/plugin/thumbnailer'

class TestImage
	include Plugin::Thumbnailer::ImageProcessing

	@@created = 0
	@@destroyed = 0

	def self.alive
		@@created - @@destroyed
	end

	def initialize
		@@created += 1
		@destroyed = false
		@final = false
	end

	def destroy!
		fail "already destroyed: #{self}" if @destroyed
		@destroyed = true
		@@destroyed += 1
		self
	end

	def copy
		TestImage.new
	end

	def destroyed?
		@destroyed
	end

	def final!
		@final = true
		self
	end

	def final?
		@final
	end
end

describe 'image processing module' do
	it '#replace will return new or original image makng sure that all other images are destroyed' do
		image = TestImage.new.replace do |image|
			image.copy.replace do |image|
				image.final!
			end
		end
		image.should be_final
		image.should_not be_destroyed

		TestImage.alive.should == 1
		image.destroy!

		image = TestImage.new.replace do |image|
			image.copy.replace do |image|
				image.copy.replace do |image|
					image.copy
				end.replace do |image|
					image.final!
				end
			end
		end
		image.should be_final
		image.should_not be_destroyed

		TestImage.alive.should == 1
		image.destroy!

		image = TestImage.new.replace do |image|
			image.copy.replace do |image|
				image = image.copy.replace do |image|
					image.copy
				end
				image.replace do |image|
					image.copy.replace do |image|
						image.final!
					end
				end
			end
		end
		image.should be_final
		image.should_not be_destroyed

		TestImage.alive.should == 1
		image.destroy!
	end

	it '#replace will destroy created images on exception' do
		lambda {
			image = TestImage.new.replace do |image|
				image.copy.replace do |image|
					image.copy.replace do |image|
						image.copy.replace do |image|
							fail 'test'
						end
					end
				end
			end
		}.should raise_error(RuntimeError, 'test')

		TestImage.alive.should == 0

		lambda {
			image = TestImage.new.replace do |image|
				image.copy.replace do |image|
					image.copy.replace do |image|
						image.copy
					end.replace do |image|
						fail 'test'
						image.final!
					end
				end
			end
		}.should raise_error(RuntimeError, 'test')

		TestImage.alive.should == 0
	end

	it '#use should return image to be used for multiple processing and destroy it at the end' do
		image = TestImage.new.use do |image|
			i1 = image.replace do |image|
				image.copy.final!
			end
			i1.should be_final
			i1.destroy!

			i2 = image.replace do |image|
				image.copy.final!
			end
			i2.should be_final
			i2.destroy!

			i3 = image.replace do |image|
				nil
			end
			i3.should_not be_destroyed
		end
		image.should be_destroyed

		TestImage.alive.should == 0
	end
end

