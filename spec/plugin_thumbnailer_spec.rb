require_relative 'spec_helper'
require 'unicorn-cuba-base'
require 'httpthumbnailer/plugin/thumbnailer'
require 'httpthumbnailer/thumbnail_specs'

describe Plugin::Thumbnailer::Service do
	subject do
		service = Plugin::Thumbnailer::Service.new

		service.processing_method('crop') do |image, width, height, options|
			image.resize_to_fill(width, height) if image.columns != width or image.rows != height
		end

		service.processing_method('fit') do |image, width, height, options|
			image.resize_to_fit(width, height) if image.columns != width or image.rows != height
		end

		service.processing_method('pad') do |image, width, height, options|
			image.resize_to_fit(width, height).replace do |resize|
				resize.render_on_background(options['background-color'], width, height)
			end if image.columns != width or image.rows != height
		end

		service.processing_method('limit') do |image, width, height, options|
			image.resize_to_fit(width, height) if image.columns > width or image.rows > height
		end

		service
	end

	def square_odd
		subject.load(TestImage.io('square_odd.png'))
	end

	before :each do
		@before_stats = Plugin::Thumbnailer::Service.stats.to_hash
	end

	def diff_stat(name)
		Plugin::Thumbnailer::Service.stats.to_hash[name] - @before_stats[name]
	end

	it "should load images from provided blob" do
		image = subject.load(TestImage.io('square_odd.png'))
		image.format.should == 'PNG'
		image.width.should == 99
		image.height.should == 99
	end

	describe 'thumbnailing' do
		describe 'cropping' do
			it 'should be a noop if same width and height are used as original image' do
				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 99
					thumbnail.height.should == 99
				end
				diff_stat(:total_images_created_resize).should == 0
				diff_stat(:total_images_created_crop).should == 0
			end

			it 'should be a resize operation if same proportions are used as original image' do
				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,50,50,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 50
					thumbnail.height.should == 50
				end
				diff_stat(:total_images_created_resize).should == 1
				diff_stat(:total_images_created_crop).should == 0
			end

			it 'should be a resize and crop operation if different proportions are used as original image' do
				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,50,60,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 50
					thumbnail.height.should == 60
				end
				diff_stat(:total_images_created_resize).should == 1
				diff_stat(:total_images_created_crop).should == 1
			end

			it 'should crop to even and odd proportions' do
				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,33,33,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 33
					thumbnail.height.should == 33
				end

				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,91,91,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 91
					thumbnail.height.should == 91
				end

				square_odd.thumbnail(ThumbnailSpec.from_uri('crop,33,50,png')) do |thumbnail|
					thumbnail.format.should == 'PNG'
					thumbnail.width.should == 33
					thumbnail.height.should == 50
				end
			end
		end
	end
end
