require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'httpthumbnailer/thumbnail_specs'

describe ThumbnailSpecs do
	it "can be crated from URI" do
		ts = ThumbnailSpecs.from_uri('test,128,256,JPEG,magick:64,number:8/pad,128,128,PNG,background:0xFF00FF/crop,32,32,GIF')

		ts[0].method.should == 'test'
		ts[0].width.should == 128
		ts[0].height.should == 256
		ts[0].format.should == 'JPEG'
		ts[0].mime.should == 'image/jpeg'
		ts[0].options.should == { 'magick' => '64', 'number' => '8' }

		ts[1].method.should == 'pad'
		ts[1].width.should == 128
		ts[1].height.should == 128
		ts[1].format.should == 'PNG'
		ts[1].mime.should == 'image/png'
		ts[1].options.should == { 'background' => '0xFF00FF' }

		ts[2].method.should == 'crop'
		ts[2].width.should == 32
		ts[2].height.should == 32
		ts[2].format.should == 'GIF'
		ts[2].mime.should == 'image/gif'
		ts[2].options.should == {}
	end
end

