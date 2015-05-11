module Ownership
	MovingBorrowedError = Class.new(RuntimeError)
	BorrowingAfterMoveError = Class.new(RuntimeError)
	MovingAfterMoveError = Class.new(RuntimeError)

	# TODO: add assertions
	def own
		@owned = true
		begin
			ret = yield self
			if ret == self or ret == nil
				@owned = nil
				@moved = nil
				return self
			end
			ret
		ensure
			destroy! if owned?
		end
	end

	def owned?
		@owned
	end

	def borrow
		@moved and raise BorrowingAfterMoveError, "cannot borrow after move '#{self}'"
		@owned.nil? and fail "object #{self} not owned by anyone"
		was_owned = @owned
		begin
			@owned = false
			yield self
		ensure
			@owned = was_owned
		end
	end

	def move
		@moved and raise MovingAfterMoveError, "cannot move after move '#{self}'"
		@owned or raise MovingBorrowedError, "cannot move borrowed '#{self}'"
		@owned.nil? and fail "object #{self} not owned by anyone"
		begin
			ret = yield self
			if ret == self or ret == nil
				@owned = false
				@moved = false
				return self
			end
			ret
		ensure
			destroy! if owned?
			@moved = true
			@owned = false
		end
	end

	def replace(&block)
		if @owned.nil?
			own(&block)
		elsif @owned
			move(&block)
		else
			borrow(&block)
		end
	end
end


