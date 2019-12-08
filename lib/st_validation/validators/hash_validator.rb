require_relative '../abstract_validator'

module StValidation
  module Validators
    class HashValidator < AbstractValidator
      def initialize(blueprint, factory)
        @validators = blueprint.map { |k, bp| [k, factory.build(bp)] }.to_h
      end

      def call(value)
        return false unless value.is_a?(Hash) && extra_keys(value).empty?

        validators.each { |k, v| return false unless v.call(value[k]) }
        true
      end

      private

      attr_reader :validators

      def generate_explanation(value)
        return 'not a hash' unless value.is_a?(Hash)

        result = validators
                 .reduce({}) { |a, (k, v)| a.merge(k => v.explain(value[k])) }
                 .compact

        extra_keys(value).each { |k| result[k] = 'extra key detected' }

        result.empty? ? nil : result
      end

      def extra_keys(hash)
        hash.keys - validators.keys
      end
    end
  end
end
