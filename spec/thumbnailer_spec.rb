require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thumbnailer'

describe ThumbnailSpec do
	it "should store thumbanil attributes method, widht, height and options" do
		t = ThumbnailSpec.new('pad', 128, 256, 'PNG', 'background' => '0x00ffff')
		t.method.should == 'pad'
		t.width.should == 128
		t.height.should == 256
		t.format.should == 'PNG'
		t.mime.should == 'image/png'
		t.options.should == { 'background' => '0x00ffff' }
	end

	it "should return full jpeg mime time on JPG format" do
		t = ThumbnailSpec.new('pad', 128, 256, 'JPG')
		t.format.should == 'JPG'
		t.mime.should == 'image/jpeg'
	end
end

describe Thumbnailer do
	it 'should allow adding new method of thumbnails' do
		t = Thumbnailer.new

		t.method('test') do |image, spec|
			image + spec.width + spec.height + spec.format.to_i + spec.options[:magic]
		end

		t.process_image(256, ThumbnailSpec.new('test', 128, 32, '8', :magic => 64)).should == 256 + 128 + 32 + 8 + 64
	end
end

