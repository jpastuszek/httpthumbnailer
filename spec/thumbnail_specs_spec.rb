require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'httpthumbnailer/thumbnail_specs'

describe ThumbnailSpecs do
	it "can be crated from URI" do
		ts = ThumbnailSpecs.from_uri('test,128,256,jpeg,magick:64,number:8/pad,128,128,png,background:0xFF00FF/crop,32,32,gif')

		ts[0].method.should == 'test'
		ts[0].width.should == 128
		ts[0].height.should == 256
		ts[0].format.should == 'JPEG'
		ts[0].options.should == { 'magick' => '64', 'number' => '8' }

		ts[1].method.should == 'pad'
		ts[1].width.should == 128
		ts[1].height.should == 128
		ts[1].format.should == 'PNG'
		ts[1].options.should == { 'background' => '0xFF00FF' }

		ts[2].method.should == 'crop'
		ts[2].width.should == 32
		ts[2].height.should == 32
		ts[2].format.should == 'GIF'
		ts[2].options.should == {}
	end

	it 'should provide :input symbol when input is used as width, height or format' do
		ts = ThumbnailSpecs.from_uri('test,input,256,jpeg,magick:64,number:8/pad,128,input,png,background:0xFF00FF/crop,32,32,input')

		ts[0].width.should == :input
		ts[0].height.should == 256
		ts[0].format.should == 'JPEG'

		ts[1].width.should == 128
		ts[1].height.should == :input
		ts[1].format.should == 'PNG'

		ts[2].width.should == 32
		ts[2].height.should == 32
		ts[2].format.should == :input
	end
end

