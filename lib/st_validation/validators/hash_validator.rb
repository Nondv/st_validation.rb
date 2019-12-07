require_relative '../abstract_validator'

module StValidation
  module Validators
    class HashValidator < AbstractValidator
      def initialize(blueprint, factory)
        @validators = blueprint.map { |k, bp| [k, factory.build(bp)] }.to_h
      end

      def call(value)
        return false unless value.is_a?(Hash) &&
                            (value.keys - validators.keys).empty?

        validators.each { |k, v| return false unless v.call(value[k]) }
        true
      end

      private

      attr_reader :validators
    end
  end
end
