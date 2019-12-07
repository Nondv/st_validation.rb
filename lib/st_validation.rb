require "st_validation/version"
require "st_validation/error"
require 'st_validation/validator_factory'

module StValidation
  def self.build(blueprint)
    StValidation::ValidatorFactory.new.build(blueprint)
  end
end
