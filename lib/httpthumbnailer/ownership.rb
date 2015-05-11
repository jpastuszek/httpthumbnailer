module Ownership
	MovingBorrowedError = Class.new(RuntimeError)
	BorrowingAfterMoveError = Class.new(RuntimeError)
	OwningDestroyedError = Class.new(RuntimeError)

	def owned?
		@owned
	end

	def borrow
		@destroyed and raise BorrowingAfterMoveError, "cannot borrow after move '#{self}'"
		@owned.nil? and fail "object #{self} not owned by anyone"
		was_owned = @owned
		begin
			@owned = false
			yield self
		ensure
			@owned = was_owned
		end
	end

	def own
		@destroyed and raise OwningDestroyedError, "cannot own a destoryed object '#{self}'"
		@owned == false and raise MovingBorrowedError, "cannot move borrowed '#{self}'"
		@owned = true
		begin
			ret = yield self
			if ret == self or ret == nil
				@owned = nil
				@destroyed = nil
				return self
			end
			ret
		ensure
			if owned?
				destroy!
				@destroyed = true
				@owned = false
			end
		end
	end

	alias :move :own

	def replace(&block)
		if @owned == false
			borrow(&block)
		else
			own(&block)
		end
	end
end


