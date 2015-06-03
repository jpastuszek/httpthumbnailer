require 'forwardable'

module Plugin
	module Thumbnailer
		class Service
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
				UpscaledError = Class.new RuntimeError

				include ClassLogging
				include PerfStats
				extend PerfStats
				extend Forwardable

				def initialize(image, thumbnailing_methods, edits)
					@image = image
					@thumbnailing_methods = thumbnailing_methods
					@edits = edits
				end

				def self.from_blob(blob, thumbnailing_methods, edits, options = {}, &block)
					mw = options[:max_width]
					mh = options[:max_height]
					if mw and mh
						mw = mw.to_i
						mh = mh.to_i
						log.info "using max size hint of: #{mw}x#{mh}"
					end

					begin
						image = measure "loading original image" do
							image = measure "loading image form blob" do
								begin
									images = measure "loading image form blob #{mw ? 'with' : 'without'} size hint", "#{mw*2}x#{mh*2}" do
										Magick::Image.from_blob(blob) do |info|
											if mw and mh
												define('jpeg', 'size', "#{mw*2}x#{mh*2}")
												define('jbig', 'size', "#{mw*2}x#{mh*2}")
											end
										end
									end
									begin
										image = images.shift
										begin
											if image.columns > image.base_columns or image.rows > image.base_rows and not options[:no_reload]
												log.warn "input image got upscaled from: #{image.base_columns}x#{image.base_rows} to #{image.columns}x#{image.rows}: reloading without max size hint!"
												raise UpscaledError
											end
											image
										rescue
											image.destroy!
											raise
										end
									ensure
										images.each do |other|
											other.destroy!
										end
									end
								rescue UpscaledError
									Service.stats.incr_total_images_reloaded
									mw = mh = nil
									retry
								end
							end
							image.get do |image|
								blob = nil

								log.info "loaded image: #{image.inspect.strip}"
								Service.stats.incr_total_images_loaded

								# clean up the image
								image.strip!
								image.properties do |key, value|
									log.debug "deleting user propertie '#{key}'"
									image[key] = nil
								end
								image
							end.get do |image|
								if mw and mh and not options[:no_downscale]
									f = image.find_downscale_factor(mw, mh)
									if f > 1
										measure "downscailing", image.inspect.strip do
											image = image.downscale(f)
											log.info "downscaled image by factor of #{f}: #{image.inspect.strip}"
											Service.stats.incr_total_images_downscaled
											image
										end
									end
								end
							end
						end
						image.get do |image|
							yield self.new(image, thumbnailing_methods, edits)
							true # make sure it is destroyed
						end
					rescue Magick::ImageMagickError => error
						raise ImageTooLargeError, error if error.message =~ /cache resources exhausted/
						raise UnsupportedMediaTypeError, error
					end
				end

				def thumbnail!(spec, &block)
					# it is OK if the image get's destroyed in the process
					@image.get do |image|
						_thumbnail(image, spec, &block)
					end
				end

				def thumbnail(spec, &block)
					# we don't want to destory the input image after we have generated the thumbnail so we can generate another one
					@image.borrow do |image|
						_thumbnail(image, spec, &block)
					end
				end

				def _thumbnail(image, spec)
					spec = spec.dup
					# default background is white
					spec.options['background-color'] = spec.options.fetch('background-color', 'white').sub(/^0x/, '#')

					width = spec.width == :input ? @image.columns : spec.width
					height = spec.height == :input ? @image.rows : spec.height
					image_format = spec.format == :input ? @image.format : spec.format

					raise ZeroSizedImageError.new(width, height) if width == 0 or height == 0

					begin
						measure "generating thumbnail to spec", spec do
							image.get do |image|
								if image.alpha?
									measure "rendering image on background", image.inspect.strip  do
										log.info 'image has alpha, rendering on background'
										image.render_on_background(spec.options['background-color'])
									end
								else
									image
								end
							end.get do |image|
								spec.edits.each do |edit|
									log.debug "applying edit '#{edit}'"
									image = image.get do |image|
										measure "edit", edit do
											edit_image(image, edit.name, *edit.args, edit.options, spec)
										end
									end
								end
								image
							end.get do |image|
								log.debug "thumbnailing with method '#{spec.method} #{width}x#{height} #{spec.options}'"
								measure "thumbnailing with method", "#{spec.method} #{width}x#{height} #{spec.options}" do
									thumbnail_image(image, spec.method, width, height, spec.options)
								end
							end.get do |image|
								if image.alpha?
									measure "rendering thumbnail on background", image.inspect.strip do
										log.info 'thumbnail has alpha, rendering on background'
										image.render_on_background(spec.options['background-color'])
									end
								else
									image
								end
							end.get do |image|
								Service.stats.incr_total_thumbnails_created
								yield Thumbnail.new(image, image_format, spec.options)
							end
						end
					rescue Magick::ImageMagickError => error
						raise ImageTooLargeError, error.message if error.message =~ /cache resources exhausted/
						raise
					end
				end

				def edit_image(image, name, *args, options, spec)
					impl = @edits[name] or raise UnsupportedEditError, name

					# make sure we pass as many args as expected (filling with nil)
					args_no = impl.arity - 3 # for image, optioins and spec
					args = args.dup
					args.fill(nil, (args.length)...args_no)
					if args.length > args_no
						log.warn "extra arguments to edit '#{name}': #{args[args_no..-1].join(', ')}"
						args = args[0...args_no]
					end

					ret = impl.call(image, *args, options, spec)

					fail "edit '#{name}' returned '#{ret.class.name}' - expecting nil or Magick::Image" unless ret.nil? or ret.kind_of? Magick::Image
					ret or image
				rescue PluginContext::PluginArgumentError => error
					raise EditArgumentError.new(name, error.message)
				end

				def thumbnail_image(image, method, width, height, options)
					impl = @thumbnailing_methods[method] or raise UnsupportedMethodError, method
					ret = impl.call(image, width, height, options)
					fail "thumbnailing method '#{name}' returned '#{ret.class.name}' - expecting nil or Magick::Image" unless ret.nil? or ret.kind_of? Magick::Image
					ret or image
				rescue PluginContext::PluginArgumentError => error
					raise ThumbnailArgumentError.new(method, error.message)
				end

				def_delegators :@image, :format, :width, :height

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
				include PerfStats

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

					measure "to blob", "#{@format} (quality: #{@quality} interlace: #{@interlace})" do
						@image.to_blob do
							self.format = format
							self.quality = quality if quality
							self.interlace = interlace
						end
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
		end
	end
end

