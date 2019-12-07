module StValidation
  class AbstractValidator
    def call
      raise 'implement this'
    end

    def to_proc
      ->(x) { call(x) }
    end
  end
end
