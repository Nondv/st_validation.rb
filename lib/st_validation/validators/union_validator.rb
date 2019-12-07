require_relative '../abstract_validator'

module StValidation
  module Validators
    ##
    # Checks if a value matches any of given blueprints
    #
    class UnionValidator < AbstractValidator
      def initialize(blueprint_list, factory)
        # TODO: I think it's better to raise a different kind of error and transform it later
        raise InvalidBlueprintError if blueprint_list.empty?

        @validators = blueprint_list.map { |bp| factory.build(bp) }
      end

      def call(value)
        @validators.any? { |v| v.call(value) }
      end

      private

      def generate_explanation(value)
        @validators.map { |v| v.explain(value) }
      end
    end
  end
end
