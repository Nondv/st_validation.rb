require_relative '../abstract_validator'

module StValidation
  module Validators
    class ArrayValidator < AbstractValidator
      def initialize(element_blueprint, factory)
        @validator = factory.build(element_blueprint)
      end

      def call(value)
        return false unless value.is_a?(Array)

        value.all?(&@validator)
      end

      private

      def generate_explanation(value)
        return 'not an array' unless value.is_a?(Array)

        value.map { |e| @validator.explain(e) }
      end
    end
  end
end
