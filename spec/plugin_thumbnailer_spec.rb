require_relative 'spec_helper'
require 'unicorn-cuba-base'
require 'httpthumbnailer/plugin/thumbnailer'
require 'httpthumbnailer/thumbnail_specs'

describe Plugin::Thumbnailer::Service do
	subject do
		service = Plugin::Thumbnailer::Service.new
		service.setup_default_methods
		service
	end

	def square_odd
		subject.load(TestImage.io('square_odd.png')) do |image|
			yield image
		end
	end

	def square_even
		subject.load(TestImage.io('square_even.png')) do |image|
			yield image
		end
	end

	before :each do
		@before_stats = Plugin::Thumbnailer::Service.stats.to_hash
	end

	def diff_stat(name)
		Plugin::Thumbnailer::Service.stats.to_hash[name] - @before_stats[name]
	end

	it "should load images from provided blob" do
		subject.load(TestImage.io('square_odd.png')) do |image|
			image.format.should == 'PNG'
			image.width.should == 99
			image.height.should == 99
		end
	end

	describe 'encoding' do
		describe 'interlace' do
			it 'should fail if unknown interlace is specified' do
				expect {
					square_odd do |square_odd|
						square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,jpeg,interlace:Blah')) do |thumbnail|
						end
					end
				}.to raise_error RuntimeError, 'unsupported interlace: Blah'
			end

			it 'should allow to construct progressive JPEG with interlace JPEGInterlace or LineInterlace or PlaneInerlace' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,jpeg')) do |thumbnail|
						image = Magick::Image.from_blob(thumbnail.data).first
						image.columns.should == 99
						image.rows.should == 99
						image.interlace.to_s.should == 'NoInterlace'
						image.destroy!
					end
				end

				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,jpeg,interlace:JPEGInterlace')) do |thumbnail|
						image = Magick::Image.from_blob(thumbnail.data).first
						image.columns.should == 99
						image.rows.should == 99
						image.interlace.to_s.should == 'JPEGInterlace'
						image.destroy!
					end
				end

				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,jpeg,interlace:LineInterlace')) do |thumbnail|
						image = Magick::Image.from_blob(thumbnail.data).first
						image.columns.should == 99
						image.rows.should == 99
						image.interlace.to_s.should == 'JPEGInterlace'
						image.destroy!
					end
				end

				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,jpeg,interlace:PlaneInterlace')) do |thumbnail|
						image = Magick::Image.from_blob(thumbnail.data).first
						image.columns.should == 99
						image.rows.should == 99
						image.interlace.to_s.should == 'JPEGInterlace'
						image.destroy!
					end
				end
			end
		end
	end

	describe 'thumbnailing' do
		describe 'cropping' do
			it 'should be a noop if same width and height are used as original image' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,99,99,png')) do |thumbnail|
						thumbnail.width.should == 99
						thumbnail.height.should == 99
					end
					diff_stat(:total_images_created_resize).should == 0
					diff_stat(:total_images_created_crop).should == 0
				end
			end

			it 'should be a resize operation if same proportions are used as original image' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,50,50,png')) do |thumbnail|
						thumbnail.width.should == 50
						thumbnail.height.should == 50
					end
					diff_stat(:total_images_created_resize).should == 1
					diff_stat(:total_images_created_crop).should == 0
				end
			end

			it 'should be a resize and crop operation if different proportions are used as original image' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,50,60,png')) do |thumbnail|
						thumbnail.width.should == 50
						thumbnail.height.should == 60
					end
					diff_stat(:total_images_created_resize).should == 1
					diff_stat(:total_images_created_crop).should == 1
				end
			end

			it 'should crop to even and odd proportions' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,33,33,png')) do |thumbnail|
						thumbnail.width.should == 33
						thumbnail.height.should == 33
					end
				end

				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,91,91,png')) do |thumbnail|
						thumbnail.width.should == 91
						thumbnail.height.should == 91
					end
				end

				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,33,50,png')) do |thumbnail|
						thumbnail.width.should == 33
						thumbnail.height.should == 50
					end
				end
			end

			it 'should crop with upwards scaling' do
				square_odd do |square_odd|
					square_odd.thumbnail(ThumbnailSpec.from_uri('crop,198,99,png')) do |thumbnail|
						thumbnail.width.should == 198
						thumbnail.height.should == 99
						#show_blob thumbnail.data
					end
				end
			end

			describe 'floating' do
				it 'should crop with floating horizontally' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:1.0')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:0.0')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:0.8')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:-9.8')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:3')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end
				end

				it 'should crop with floating vertically' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-y:1.0')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-y:0.0')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-y:0.8')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-y:-9.8')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-y:3')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end
				end

				it 'should crop with floating horizontally and vertically' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,100,200,png,float-x:0.25,float-y:0.25')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('crop,200,100,png,float-x:0.25,float-y:0.25')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end
				end

				it 'should pad with floating horizontaly' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:1.0')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:0.0')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:0.8')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:-9.8')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:3')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end
				end

				it 'should pad with floating verticaly' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-y:1.0')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-y:0.0')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-y:0.8')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-y:-9.8')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-y:3')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end
				end

				it 'should pad with floating horizontally and vertically' do
					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,100,200,png,float-x:0.25,float-y:0.25')) do |thumbnail|
							thumbnail.width.should == 100
							thumbnail.height.should == 200
							#show_blob thumbnail.data
						end
					end

					square_even do |square_even|
						square_even.thumbnail(ThumbnailSpec.from_uri('pad,200,100,png,float-x:0.25,float-y:0.25')) do |thumbnail|
							thumbnail.width.should == 200
							thumbnail.height.should == 100
							#show_blob thumbnail.data
						end
					end
				end
			end
		end
	end
end
