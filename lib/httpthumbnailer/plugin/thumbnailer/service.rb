require_relative 'service/magick'
require_relative 'service/images'
require_relative 'service/built_in_plugins'

module Plugin
	module Thumbnailer
		class Service
			include ClassLogging

			extend Stats
			def_stats(
				:total_images_loaded,
				:total_images_reloaded,
				:total_images_downscaled,
				:total_thumbnails_created,
				:images_loaded,
				:max_images_loaded,
				:max_images_loaded_worker,
				:total_images_created,
				:total_images_destroyed,
				:total_images_created_from_blob,
				:total_images_created_initialize,
				:total_images_created_initialize_copy,
				:total_images_created_resize,
				:total_images_created_crop,
				:total_images_created_sample,
				:total_images_created_blur_image,
				:total_images_created_composite,
				:total_images_created_rotate
			)

			def self.input_formats
				Magick.formats.select do |name, mode|
					mode.include? 'r'
				end.keys.map(&:downcase)
			end

			def self.output_formats
				Magick.formats.select do |name, mode|
					mode.include? 'w'
				end.keys.map(&:downcase)
			end

			def self.rmagick_version
				Magick::Version
			end

			def self.magick_version
				Magick::Magick_version
			end

			def initialize(options = {})
				InputImage.logger = logger_for(InputImage)
				Thumbnail.logger = logger_for(Thumbnail)

				@thumbnailing_methods = {}
				@edits = {}
				@options = options
				@images_loaded = 0

				log.info "initializing thumbnailer: #{self.class.rmagick_version} #{self.class.magick_version}"

				set_limit(:area, options[:limit_area]) if options.member?(:limit_area)
				set_limit(:memory, options[:limit_memory]) if options.member?(:limit_memory)
				set_limit(:map, options[:limit_map]) if options.member?(:limit_map)
				set_limit(:disk, options[:limit_disk]) if options.member?(:limit_disk)

				Magick.trace_proc = lambda do |which, description, id, method|
					case which
					when :c
						Service.stats.incr_images_loaded
						@images_loaded += 1
						Service.stats.max_images_loaded = Service.stats.images_loaded if Service.stats.images_loaded > Service.stats.max_images_loaded
						Service.stats.max_images_loaded_worker = @images_loaded if @images_loaded > Service.stats.max_images_loaded_worker
						Service.stats.incr_total_images_created
						case method
						when :from_blob
							Service.stats.incr_total_images_created_from_blob
						when :initialize
							Service.stats.incr_total_images_created_initialize
						when :initialize_copy
							Service.stats.incr_total_images_created_initialize_copy
						when :resize
							Service.stats.incr_total_images_created_resize
						when :resize!
							Service.stats.incr_total_images_created_resize
						when :crop
							Service.stats.incr_total_images_created_crop
						when :crop!
							Service.stats.incr_total_images_created_crop
						when :sample
							Service.stats.incr_total_images_created_sample
						when :blur_image
							Service.stats.incr_total_images_created_blur_image
						when :composite
							Service.stats.incr_total_images_created_composite
						when :rotate
							Service.stats.incr_total_images_created_rotate
						else
							log.warn "uncounted image creation method: #{method}"
						end
					when :d
						Service.stats.decr_images_loaded
						@images_loaded -= 1
						Service.stats.incr_total_images_destroyed
					end
					log.debug{"image event: #{which}, #{description}, #{id}, #{method}: loaded images: #{Service.stats.images_loaded}"}
				end
			end

			def load(io, options = {}, &block)
				blob = io.read

				old_memory_limit = nil
				borrowed_memory_limit = nil
				if options.member?(:limit_memory)
					borrowed_memory_limit = options[:limit_memory].borrow(options[:limit_memory].limit, 'image magick')
					old_memory_limit = set_limit(:memory, borrowed_memory_limit)
				end

				InputImage.from_blob(blob, @thumbnailing_methods, @edits, options, &block)
			ensure
				if old_memory_limit
					set_limit(:memory, old_memory_limit)
					options[:limit_memory].return(borrowed_memory_limit, 'image magick')
				end
			end

			def thumbnailing_method(method, &impl)
				log.info "adding thumbnailing method: #{method}"
				@thumbnailing_methods[method] = impl
			end

			def edit(name, &impl)
				log.info "adding edit: #{name}(#{impl.parameters.drop(1).map{|p| p.last.to_s}.join(', ')})"
				@edits[name] = impl
			end

			def set_limit(limit, value)
				old = Magick.limit_resource(limit, value)
				log.info "changed #{limit} limit from #{old} to #{value} bytes"
				old
			end

			def load_plugin(plugin_context)
				plugin_context.thumbnailing_methods.each do |name, block|
					thumbnailing_method(name, &block)
				end

				plugin_context.edits.each do |name, block|
					edit(name, &block)
				end
			end

			def setup_built_in_plugins
				log.info("loading built in plugins")
				load_plugin(self.class.built_in_plugin)
			end
		end
	end
end

