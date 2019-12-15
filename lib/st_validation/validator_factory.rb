require_relative 'abstract_validator'

module StValidation
  class ValidatorFactory
    class ProcValidatorWrapper < AbstractValidator
      def initialize(proc_object)
        @proc_object = proc_object
      end

      def call(value)
        @proc_object.call(value)
      end

      private

      def generate_explanation(value)
        return nil if call(value)

        @proc_object.source_location
      end
    end

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
      result = ProcValidatorWrapper.new(result) if result.is_a?(Proc)

      raise InvalidBlueprintError unless result.is_a?(AbstractValidator)

      result
    end

    def with_extra_transformations(*extra_transformations)
      ValidatorFactory.new(transformations + extra_transformations)
    end
  end
end
