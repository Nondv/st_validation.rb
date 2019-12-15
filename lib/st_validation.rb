require 'set'

require_relative "st_validation/version"
require_relative "st_validation/errors"
require_relative 'st_validation/validator_factory'

Dir[File.join(__dir__, 'st_validation', 'validators', '*.rb')].each { |file| require file }

module StValidation
  class << self
    def build(blueprint)
      default_factory.build(blueprint)
    end

    def default_factory
      with_transformations(*default_transformations)
    end

    def with_transformations(*transformations)
      StValidation::ValidatorFactory.new(transformations)
    end

    def default_transformations
      [
        ->(bp, _factory) { bp.is_a?(Class) ? class_validator(bp) : bp },
        ->(bp, factory) { bp.is_a?(Set) ? union_validator(bp, factory) : bp },
        ->(bp, factory) { bp.is_a?(Hash) ? hash_validator(bp, factory) : bp },
        ->(bp, factory) { bp.is_a?(Array) && bp.size == 1 ? array_validator(bp[0], factory) : bp }
      ]
    end

    def alternative1
      [
        ->(bp, _) { bp.is_a?(Class) ? class_validator(bp) : bp },
        ->(bp, f) { bp.is_a?(Hash) ? hash_validator(bp, f) : bp },
        ->(bp, f) { bp.is_a?(Set) ? union_validator(bp, f) : bp },
        ->(bp, f) { bp.is_a?(Array) ? intersect_validator(bp, f) : bp }
      ]
    end

    def alternative2
      [
        ->(bp, _) { bp.is_a?(Class) ? class_validator(bp) : bp },
        ->(bp, f) { bp.is_a?(Hash) ? hash_validator(bp, f) : bp },
        ->(bp, f) { bp.is_a?(Array) && bp[0] == :and ? intersect_validator(bp[1..-1], f) : bp },
        ->(bp, f) { bp.is_a?(Array) && bp[0] == :or ? union_validator(bp[1..-1], f) : bp },
        ->(bp, f) { bp.is_a?(Array) && bp[0] == :array ? array_validator(bp[1], f) : bp }
      ]
    end

    private

    def class_validator(klass)
      Validators::ClassValidator.new(klass)
    end

    def union_validator(blueprint, factory)
      Validators::UnionValidator.new(blueprint, factory)
    end

    def intersect_validator(blueprint, factory)
      Validators::IntersectValidator.new(blueprint, factory)
    end

    def array_validator(blueprint, factory)
      Validators::ArrayValidator.new(blueprint, factory)
    end

    def hash_validator(blueprint, factory)
      Validators::HashValidator.new(blueprint, factory)
    end
  end
end
