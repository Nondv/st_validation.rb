module StValidation
  class AbstractValidator
    def call(_value)
      raise 'implement this'
    end

    def to_proc
      ->(x) { call(x) }
    end

    def explain(value)
      generate_explanation(value)
    rescue StandardError => error
      "#explain failed with #{error.class}: #{error.message}"
    end

    private

    def generate_explanation(_value)
      raise "#{self.class}#generate_explanation is not implemented"
    end
  end
end
