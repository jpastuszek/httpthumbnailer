require_relative 'spec_helper'
require 'httpthumbnailer/thumbnail_specs'

describe ThumbnailSpecs do
	it "can be created from URI" do
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

	it 'should provide editing specs' do
		ts = ThumbnailSpecs.from_uri('test,input,256,jpeg,magick:64,number:8!blur,1,2,abc:x,xyz:2!cut,1,2,3,4/pad,128,input,png,background:0xFF00FF!blur,2,2,abc:x,xyz:2!cut,2,2,3,4/crop,32,32,input!blur,3,2,abc:x,xyz:2!cut,3,2,3,4')

		ts[0].edits[0].name.should == 'blur'
		ts[0].edits[0].args.should == ['1', '2', {'abc' => 'x', 'xyz' => '2'}]
		ts[0].edits[1].name.should == 'cut'
		ts[0].edits[1].args.should == ['1', '2', '3', '4']

		ts[1].edits[0].name.should == 'blur'
		ts[1].edits[0].args.should == ['2', '2', {'abc' => 'x', 'xyz' => '2'}]
		ts[1].edits[1].name.should == 'cut'
		ts[1].edits[1].args.should == ['2', '2', '3', '4']

		ts[2].edits[0].name.should == 'blur'
		ts[2].edits[0].args.should == ['3', '2', {'abc' => 'x', 'xyz' => '2'}]
		ts[2].edits[1].name.should == 'cut'
		ts[2].edits[1].args.should == ['3', '2', '3', '4']
	end
end

