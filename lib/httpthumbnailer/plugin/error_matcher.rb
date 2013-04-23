module Plugin
  module ErrorMatcher
    def error(*klass)
      klass.any?{|k| env["app.error"].is_a? k}
    end

    def error?
      env.has_key? "app.error"
    end
  end
end

