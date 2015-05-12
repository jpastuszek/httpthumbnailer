require 'RMagick'
require 'forwardable'
require 'httpthumbnailer/ownership'

module Plugin
	module Thumbnailer
		module MimeType
			# ImageMagick Image.mime_type is absolutely bunkers! It goes over file system to look for some strange files WTF?!
			# Also it cannot be used for thumbnails since they are not yet rendered to desired format
			# Here is stupid implementation
			def mime_type
				#TODO: how do I do it better?
				mime = case format
					when 'JPG' then 'jpeg'
					else format.downcase
				end
				"image/#{mime}"
			end
		end

		class InputImage
			include ClassLogging
			extend Forwardable

			def initialize(image, thumbnailing_methods, edits)
				@image = image
				@thumbnailing_methods = thumbnailing_methods
				@edits = edits
			end

			def thumbnail(spec)
				spec = spec.dup
				# default background is white
				spec.options['background-color'] = spec.options.fetch('background-color', 'white').sub(/^0x/, '#')

				width = spec.width == :input ? @image.columns : spec.width
				height = spec.height == :input ? @image.rows : spec.height

				raise ZeroSizedImageError.new(width, height) if width == 0 or height == 0

				begin
					# we don't want to destory the image after we have generated the thumbnail
					@image.borrow do |image|
						image.get do |image|
							if image.alpha?
								log.info 'image has alpha, rendering on background'
								image.render_on_background(spec.options['background-color'])
							else
								image
							end
						end.get do |image|
							spec.edits.each do |edit|
								log.debug "applying edit: #{edit}"
								image = image.get do |image|
									edit_image(image, edit.name, *edit.args, edit.options, spec)
								end
							end
							image
						end.get do |image|
							log.debug "thumbnailing with method: #{spec.method} #{width}x#{height} #{spec.options}"
							thumbnail_image(image, spec.method, width, height, spec.options)
						end.get do |image|
							if image.alpha?
								log.info 'thumbnail has alpha, rendering on background'
								image.render_on_background(spec.options['background-color'])
							else
								image
							end
						end.get do |image|
							Service.stats.incr_total_thumbnails_created
							image_format = spec.format == :input ? @image.format : spec.format

							yield Thumbnail.new(image, image_format, spec.options)
						end
					end
				rescue Magick::ImageMagickError => error
					raise ImageTooLargeError, error.message if error.message =~ /cache resources exhausted/
					raise
				end
			end

			def edit_image(image, name, *args)
				impl = @edits[name] or raise UnsupportedEditError, name
				ret = impl.call(image, *args)
				fail "edit '#{name}' returned '#{ret.class.name}' - expecting nil or Magick::Image" unless ret.nil? or ret.kind_of? Magick::Image
				ret or image
			end

			def thumbnail_image(image, method, width, height, options)
				impl = @thumbnailing_methods[method] or raise UnsupportedMethodError, method
				ret = impl.call(image, width, height, options)
				fail "thumbnailing method '#{name}' returned '#{ret.class.name}' - expecting nil or Magick::Image" unless ret.nil? or ret.kind_of? Magick::Image
				ret or image
			end

			def_delegators :@image, :destroy!, :destroyed?, :format, :width, :height

			include MimeType

			# We use base values since it might have been loaded with size hint and prescaled
			def width
				@image.base_columns
			end

			def height
				@image.base_rows
			end
		end

		class Thumbnail
			include ClassLogging
			extend Forwardable

			def initialize(image, format, options = {})
				@image = image
				@format = format

				@quality = (options['quality'] or default_quality(format))
				@quality &&= @quality.to_i

				@interlace = (options['interlace'] or 'NoInterlace')
				fail "unsupported interlace: #{@interlace}" unless Magick::InterlaceType.values.map(&:to_s).include? @interlace
				@interlace = Magick.const_get @interlace.to_sym
			end

			attr_reader :format
			def_delegators :@image, :width, :height

			#def_delegators :@image, :format

			def data
				# export class variables to local scope
				format = @format
				quality = @quality
				interlace = @interlace

				@image.to_blob do
					self.format = format
					self.quality = quality if quality
					self.interlace = interlace
				end
			end

			include MimeType

			private

			def default_quality(format)
				case format
				when /png/i
					95 # max zlib compression, adaptive filtering (photo)
				when /jpeg|jpg/i
					85
				else
					nil
				end
			end
		end

		class Magick::Image
			include Ownership
			### WARNING: 'raise' is overwritten with an image operation method; use Kernel::raise instead!

			def self.new_8bit(width, height, background_color = "none")
				Magick::Image.new(width, height) {
					self.depth = 8
					begin
						self.background_color = background_color
					rescue ArgumentError
						Kernel::raise Plugin::Thumbnailer::InvalidColorNameError.new(background_color)
					end
				}
			end

			def render_on_background(background_color, width = nil, height = nil, float_x = 0.5, float_y = 0.5)
				# default to image size
				width ||= self.columns
				height ||= self.rows

				# make sure we have enough background to fit image on top of it
				width = self.columns if width < self.columns
				height = self.rows if height < self.rows

				self.class.new_8bit(width, height, background_color).get do |background|
					background.composite!(self, *background.float_to_offset(self.columns, self.rows, float_x, float_y), Magick::OverCompositeOp)
				end
			end

			# non coping version
			def resize_to_fill(width, height = nil, float_x = 0.5, float_y = 0.5)
				# default to square
				height ||= width

				return if width == columns and height == rows

				scale = [width / columns.to_f, height / rows.to_f].max

				resize((scale * columns).ceil, (scale * rows).ceil).get do |image|
					next if width == image.width and height == image.height
					image.crop(*image.float_to_offset(width, height, float_x, float_y), width, height, true)
				end
			end

			# make rotate not to change image.page to avoid WTF moments
			alias :rotate_orig :rotate
			def rotate(*args)
				out = rotate_orig(*args)
				out.page = Magick::Rectangle.new(out.columns, out.rows, 0, 0)
				out
			end

			def downscale(f)
				sample(columns / f, rows / f)
			end

			def find_downscale_factor(max_width, max_height, factor = 1)
				new_factor = factor * 2
				if columns / new_factor > max_width * 2 and rows / new_factor > max_height * 2
					find_downscale_factor(max_width, max_height, factor * 2)
				else
					factor
				end
			end

			def float_to_offset(float_width, float_height, float_x = 0.5, float_y = 0.5)
				base_width = self.columns
				base_height = self.rows

				x = ((base_width - float_width) * float_x).ceil
				y = ((base_height - float_height) * float_y).ceil

				x = 0 if x < 0
				x = (base_width - float_width) if x > (base_width - float_width)

				y = 0 if y < 0
				y = (base_height - float_height) if y > (base_height - float_height)

				[x, y]
			end

			def blur_region(x, y, h, w, radious, sigma)
				blur_image(radious, sigma).get do |blur|
					blur.crop(x, y, h, w, true)
				end.get do |blur|
					self.composite!(blur, x, y, Magick::OverCompositeOp)
				end
			end

			# helpers

			def with_background_color(color)
				if color
					was = self.background_color
					begin
						begin
							self.background_color = color
						rescue ArgumentError
							Kernel::raise Plugin::Thumbnailer::InvalidColorNameError.new(color)
						end
						yield
					ensure
						self.background_color = was
					end
				else
					yield
				end
			end

			def rel_to_px(x, y)
				[x * columns, y * rows]
			end

			def px_to_rel(x, y)
				[x / columns, y / rows]
			end

			def width
				columns
			end

			def height
				rows
			end
		end
	end
end

