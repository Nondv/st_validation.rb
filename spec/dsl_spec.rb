require 'spec_helper'
require_relative '../lib/st_validation'

RSpec.describe 'DSL examples' do
  shared_examples 'examples' do
    it 'user data' do
      expect(
        is_user.call(
          id: 123,
          email: 'user@example.com',
          admin: false,
          favourite_fruit: 'apple',
          info: {
            phone: '123456',
            notes: nil
          }
        )
      ).to be true

      expect(
        is_user.call(
          id: 123,
          email: 'user@example.com',
          admin: false,
          favourite_fruit: 'cucumber',
          info: {
            phone: '123456',
            notes: nil
          },
          extra: nil
        )
      ).to be false
    end

    it 'int' do
      expect(is_int.call(1)).to be true
      expect(is_int.call(1.0)).to be false
      expect(is_int.call('1')).to be false
      expect(is_int.call(nil)).to be false
    end

    it 'int array' do
      expect(is_int_array.call([1, 2, 3])).to be true
      expect(is_int_array.call([])).to be true
      expect(is_int_array.call(nil)).to be false
      expect(is_int_array.call(%w[1 2 3])).to be false
      expect(is_int_array.call(['1', 2, 3])).to be false
      expect(is_int_array.call([1, 2, '3'])).to be false
    end

    it 'maybe int' do
      expect(is_maybe_int.call(1)).to be true
      expect(is_maybe_int.call(nil)).to be true
    end

    it 'one of fruits' do
      expect(is_one_of_fruits.call('apple')).to be true
      expect(is_one_of_fruits.call('orange')).to be true
      expect(is_one_of_fruits.call('cucumber')).to be false
      expect(is_one_of_fruits.call('almond')).to be false
    end
  end

  describe 'default' do
    let(:factory) { StValidation.with_transformations(StValidation.default_transformations) }
    let(:is_int) { factory.build(Integer) }
    let(:is_maybe_int) { factory.build(Set[NilClass, Integer]) }
    let(:is_int_array) { factory.build([Integer]) }
    let(:is_one_of_fruits) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:is_user) do
      factory.build(
        id: Integer,
        email: ->(x) { x.is_a?(String) && !!(x =~ /.+\@.+/) },
        admin: Set[TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits,
        info: {
          phone: String,
          notes: Set[NilClass, String]
        }
      )
    end

    include_examples 'examples'
  end

  describe 'alternative1' do
    let(:factory) { StValidation.with_transformations(StValidation.alternative1) }
    let(:is_int) { factory.build(Integer) }
    let(:is_maybe_int) { factory.build(Set[NilClass, Integer]) }
    let(:is_int_array) { factory.build([Array, ->(x) { x.all?(&is_int) }]) }
    let(:is_one_of_fruits) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:is_user) do
      factory.build(
        id: Integer,
        email: [String, ->(x) { x =~ /.+\@.+/ }],
        admin: Set[TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits,
        info: {
          phone: String,
          notes: Set[NilClass, String]
        }
      )
    end

    include_examples 'examples'
  end

  describe 'alternative2' do
    let(:factory) { StValidation.with_transformations(StValidation.alternative2) }
    let(:is_int) { factory.build(Integer) }
    let(:is_maybe_int) { factory.build([:or, NilClass, Integer]) }
    let(:is_int_array) { factory.build([:and, Array, ->(x) { x.all?(&is_int) }]) }
    let(:is_one_of_fruits) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:is_user) do
      factory.build(
        id: Integer,
        email: [:and, String, ->(x) { x =~ /.+\@.+/ }],
        admin: [:or, TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits,
        info: {
          phone: String,
          notes: [:or, NilClass, String]
        }
      )
    end

    include_examples 'examples'
  end
end
