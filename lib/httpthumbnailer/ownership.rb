module Ownership
	UseDestroyedError = Class.new(RuntimeError)
	BorrowingDestoryedError = Class.new(RuntimeError)
	BorrowingNotOwnedError = Class.new(RuntimeError)

	def owned?
		@owned
	end

	def borrowed?
		@borrowed
	end

	def borrow
		@destroyed and Kernel::raise BorrowingDestoryedError, "cannot borrow a destroyed obejct '#{self}'"
		@owned or Kernel::raise BorrowingNotOwnedError, "cannot borrow not owned object '#{self}'"
		was_borrowed = @borrowed
		begin
			@borrowed = true
			yield self
		ensure
			@borrowed = was_borrowed
		end
	end

	def get(&block)
		if @borrowed
			borrow(&block)
		else
			@destroyed and Kernel::raise UseDestroyedError, "cannot own a destoryed object '#{self}'"
			# take ownership; it may be owned already
			@owned = true
			begin
				ret = yield self
				# give up ownership if nothing happened with the obejct
				# NOTE: we use equal here sice == may actually test pixel by pixel which is not the point!
				if ret.equal?(self) or ret.nil?
					@owned = nil
					return self
				end
				ret
			ensure
				# if I am still an owner destroy and give up ownership
				if @owned
					destroy!
					@destroyed = true
					@owned = nil
				end
			end
		end
	end
end


