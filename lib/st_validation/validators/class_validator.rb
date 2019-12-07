require_relative '../abstract_validator'

module StValidation
  module Validators
    class ClassValidator < AbstractValidator
      def initialize(klass)
        @klass = klass
      end

      def call(value)
        value.is_a?(@klass)
      end
    end
  end
end
