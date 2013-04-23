module Plugin
  module ErrorMatcher
    def error(*klass)
      klass.any?{|k| env["ERROR"].is_a? k}
    end

    def error?
      env.has_key? "ERROR"
    end
  end
end

