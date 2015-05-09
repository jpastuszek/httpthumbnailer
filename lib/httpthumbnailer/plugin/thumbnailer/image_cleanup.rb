module Plugin
	module Thumbnailer
		module ImageProcessing
			def replace
				@use_count ||= 0
				processed = nil
				begin
					processed = yield self
					processed = self unless processed
					fail 'got destroyed image' if processed.destroyed?
				ensure
					self.destroy! if @use_count <= 0 unless processed.equal? self
				end
				processed
			end

			def borrow
				@use_count ||= 0
				@use_count += 1
				begin
					yield self
					self
				ensure
					@use_count -=1
					self.destroy! if @use_count <= 0
				end
			end
		end
	end
end
