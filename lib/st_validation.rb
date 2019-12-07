require "st_validation/version"
require "st_validation/errors"
require 'st_validation/validator_factory'

Dir[File.join(__dir__, 'st_validation', 'validators', '*.rb')].each { |file| require file }

module StValidation
  class << self
    def build(blueprint)
      StValidation::ValidatorFactory.new(basic_transformations).build(blueprint)
    end

    def with_extra_transformations(*transformations)
      all_transformations = transformations + basic_transformations
      StValidation::ValidatorFactory.new(all_transformations)
    end

    def basic_transformations
      [
        ->(bp, _factory) { bp.is_a?(Class) ? class_validator(bp) : bp },
        ->(bp, factory) { bp.is_a?(Set) ? union_validator(bp, factory) : bp },
        ->(bp, factory) { bp.is_a?(Hash) ? hash_validator(bp, factory) : bp },
        ->(bp, factory) { bp.is_a?(Array) && bp.size == 1 ? array_validator(bp[0], factory) : bp }
      ]
    end

    private

    def class_validator(klass)
      Validators::ClassValidator.new(klass)
    end

    def union_validator(blueprint, factory)
      Validators::UnionValidator.new(blueprint, factory)
    end

    def array_validator(blueprint, factory)
      Validators::ArrayValidator.new(blueprint, factory)
    end

    def hash_validator(blueprint, factory)
      Validators::HashValidator.new(blueprint, factory)
    end
  end
end
