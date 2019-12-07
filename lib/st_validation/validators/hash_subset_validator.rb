require_relative '../abstract_validator'
require_relative 'hash_validator'

module StValidation
  module Validators
    # Use this when you don't care if there're extra keys set
    class HashSubsetValidator < AbstractValidator
      def initialize(blueprint, factory = StValidation.basic_factory)
        @keys = blueprint.keys
        @hash_validator = StValidation::Validators::HashValidator.new(blueprint, factory)
      end

      def call(value)
        return false unless value.is_a?(Hash)

        @hash_validator.call(value.slice(*keys))
      end

      private

      attr_reader :keys, :hash_validator
    end
  end
end
