require 'pp'
require 'rspec/expectations'

RSpec::Matchers.define :pass_st_validation do |validator|
  unless validator.is_a?(StValidation::AbstractValidator)
    validator = StValidation.build(validator)
  end

  match do |actual|
    validator.call(actual)
  end

  failure_message do |actual|
    output = PP.pp(validator.explain(actual), '')
    "value didn't pass St. Validation. #explain output:\n#{output}"
  end

  failure_message_when_negated do |_actual|
    "value wasn't supposed pass St. Validation"
  end
end
