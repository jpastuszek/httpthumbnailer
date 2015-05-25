require 'RMagick'
require 'httpthumbnailer/ownership'

### WARNING: 'raise' is overwritten with an image operation method; use Kernel::raise instead!
class Magick::Image
	include Ownership
	include ClassLogging
	include PerfStats

	# use this on image before doing in-place (like composite!) edit so borrowed images are not changed
	def get_for_inplace
		get do |image|
			if image.borrowed?
				yield image.copy
			else
				yield image
			end
		end
	end

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

		get do |image| # this will comsume (destory) self just after resize
			image.resize((scale * columns).ceil, (scale * rows).ceil)
		end.get do |image|
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

	def pixelate_region(x, y, w, h, size)
		factor = 1.0 / size

		# what happens here
		# 1. get an required box cut form the image
		# 2. resize it down by fracto
		# 3. resize it back up by factor
		# 4. since we may end up with bigger image (due to size of the pixelate pixel) crop it to required size again
		# 5. composite over the original image in required position

		crop(x, y, w, h, true).get do |work_space|
			work_space.sample((factor * w).ceil, (factor * h).ceil)
		end.get do |image|
			image.sample(size)
		end.get do |image|
			image.crop(0, 0 , w, h, true)
		end.get do |image|
			p [x + w, y + h]
			get_for_inplace do |orig|
				orig.composite!(image, x, y, Magick::OverCompositeOp)
			end
		end
	end

	def blur_region(x, y, w, h, radious, sigma)
		# NOTE: we need to have bigger region to blure then the final regios to prevent edge artifacts
		# TODO: how do I calculate margin better? See: https://github.com/trevor/ImageMagick/blob/82d683349c7a6adc977f6f638f1b340e01bf0ea9/branches/ImageMagick-6.5.9/magick/gem.c#L787
		margin = [3, radious, sigma].max.ceil

		mx = x - margin
		my = y - margin
		mw = w + margin
		mh = h + margin

		# limit the box with margin to available image size
		mx = 0 if mx < 0
		my = 0 if my < 0
		mw = width - mx if mw + mx > width
		mh = height - my if mh + my > height

		#p [x, y, w, h]
		#p [mx, my, mw, mh]
		#p [x - mx, y - my, w, h]

		crop(mx, my, mw, mh, true).get do |work_space|
			work_space.blur_image(radious, sigma)
		end.get do |blur|
			blur.crop(x - mx, y - my, w, h, true)
		end.get do |blur|
			get_for_inplace do |orig|
				orig.composite!(blur, x, y, Magick::OverCompositeOp)
			end
		end
	end

	def render_rectangle(x, y, w, h, color)
			get_for_inplace do |orig|
				gc = Magick::Draw.new
				gc.fill = color
				gc.rectangle(x, y, x + w - 1, y + h - 1)
				gc.draw(orig)
				orig
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

	def rel_to_px_pos(x, y)
		[(x * columns).floor, (y * rows).floor]
	end

	def rel_to_px_dim(width, height)
		[(width * columns).ceil, (height * rows).ceil]
	end

	def rel_to_px_box(x, y, width, height)
		[*rel_to_px_pos(x, y), *rel_to_px_dim(width, height)]
	end

	def rel_to_diagonal(v)
		v * diagonal
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

	def diagonal
		@_diag ||= Math.sqrt(width ** 2 + height ** 2)
	end
end

