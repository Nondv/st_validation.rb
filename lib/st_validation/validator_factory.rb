require_relative 'validators/hash_validator'
require_relative 'validators/hash_subset_validator'

module StValidation
  class ValidatorFactory
    class InvalidBlueprintError < StValidation::Error; end

    def build(blueprint)
      case blueprint
      when Proc, StValidation::Validators::AbstractValidator
        blueprint
      when Class
        ->(x) { x.is_a?(blueprint) }
      when Set
        set_validator(blueprint)
      when Array
        array_validator(blueprint)
      when Hash
        StValidation::Validators::HashValidator.new(blueprint)
      else
        raise InvalidBlueprintError
      end
    end

    private

    def array_validator(blueprint)
      raise InvalidBlueprintError unless blueprint.is_a?(Array) && blueprint.size == 1

      element_validator = build(blueprint[0])
      ->(x) { x.is_a?(Array) && x.all?(&element_validator) }
    end

    # union validator ?
    def set_validator(blueprint)
      raise InvalidBlueprintError unless blueprint.is_a?(Set) && blueprint.size.positive?

      inner_validators = blueprint.map { |b| build(b) }
      ->(x) { inner_validators.any? { |v| v.call(x) } }
    end
  end
end
