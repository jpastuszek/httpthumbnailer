class ErrorReporter < Controller
	self.define do
		on error Plugin::Thumbnailer::UnsupportedMediaTypeError do |error|
			write_error 415, error
		end

		on error(
			Plugin::Thumbnailer::ImageTooLargeError,
			MemoryLimit::MemoryLimitedExceededError
		)	do |error|
			write_error 413, error
		end

		on error(
			ThumbnailSpec::InvalidFormatError,
			Plugin::Thumbnailer::ZeroSizedImageError,
			Plugin::Thumbnailer::UnsupportedMethodError,
			Plugin::Thumbnailer::InvalidColorNameError,
			Plugin::Thumbnailer::ThumbnailArgumentError,
			Plugin::Thumbnailer::EditArgumentError
		) do |error|
			write_error 400, error
		end

		run DefaultErrorReporter
	end
end

