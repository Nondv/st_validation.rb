module StValidation
  class ValidatorFactory
    attr_reader :transformations

    def initialize(transformations = [])
      @transformations = transformations
    end

    def build(blueprint)
      result = blueprint
      loop do
        old = result
        result = transformations.reduce(result) { |res, t| t.call(res, self) }
        break if result == old
      end

      raise InvalidBlueprintError unless result.is_a?(Proc) || result.is_a?(AbstractValidator)

      result
    end
  end
end
