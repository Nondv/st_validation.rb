require 'spec_helper'

require_relative '../../../lib/st_validation'
require_relative '../../../lib/st_validation/rspec'

RSpec.describe 'Usage' do
  it '#pass_st_validation' do
    expect(id: 123, info: { name: 'John', age: 50 }).to(
      pass_st_validation(
        id: Integer,
        info: { name: String, age: Integer }
      )
    )
  end
end
