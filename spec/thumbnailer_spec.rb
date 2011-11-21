require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thumbnailer'

describe ThumbnailSpec do
	it "should store thumbanil attributes method, widht, height and options" do
		t = ThumbnailSpec.new('pad', 128, 256, 'background' => '0x00ffff')
		t.method.should == 'pad'
		t.width.should == 128
		t.height.should == 256
		t.options.should == { 'background' => '0x00ffff' }
	end
end

describe Thumbnailer do
	it 'should allow adding new method of thumbnails' do
		t = Thumbnailer.new

		t.method('test') do |image, spec|
			spec.width + spec.height + spec.options[:magic]
		end

		t.process_image(nil, ThumbnailSpec.new('test', 128, 32, :magic => 64)).should == 128 + 32 + 64
	end
end
