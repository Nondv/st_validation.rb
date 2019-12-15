require 'spec_helper'
require_relative '../lib/st_validation'

RSpec.describe 'DSL examples' do
  shared_examples 'examples' do
    it 'user data' do
      is_user = factory.build(is_user_bp)
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
      is_int = factory.build(is_int_bp)
      expect(is_int.call(1)).to be true
      expect(is_int.call(1.0)).to be false
      expect(is_int.call('1')).to be false
      expect(is_int.call(nil)).to be false
    end

    it 'int array' do
      is_int_array = factory.build(is_int_array_bp)
      expect(is_int_array.call([1, 2, 3])).to be true
      expect(is_int_array.call([])).to be true
      expect(is_int_array.call(nil)).to be false
      expect(is_int_array.call(%w[1 2 3])).to be false
      expect(is_int_array.call(['1', 2, 3])).to be false
      expect(is_int_array.call([1, 2, '3'])).to be false
    end

    it 'maybe int' do
      is_maybe_int = factory.build(is_maybe_int_bp)
      expect(is_maybe_int.call(1)).to be true
      expect(is_maybe_int.call(nil)).to be true
    end

    it 'bool' do
      is_bool = factory.build(is_bool_bp)
      expect(is_bool.call(true)).to be true
      expect(is_bool.call(false)).to be true
      expect(is_bool.call(nil)).to be false
      expect(is_bool.call(123)).to be false
    end

    it 'one of fruits' do
      is_one_of_fruits = factory.build(is_one_of_fruits_bp)
      expect(is_one_of_fruits.call('apple')).to be true
      expect(is_one_of_fruits.call('orange')).to be true
      expect(is_one_of_fruits.call('cucumber')).to be false
      expect(is_one_of_fruits.call('almond')).to be false
    end

    it 'regexp' do
      matches_regexp = factory.build(regexp_bp)
      expect(matches_regexp.call('abc')).to be true
      expect(matches_regexp.call('xx_abc_xx')).to be true
      expect(matches_regexp.call('ab')).to be false
      expect(matches_regexp.call('acb')).to be false
      expect(matches_regexp.call(nil)).to be false
    end
  end

  describe 'default' do
    let(:factory) { StValidation.with_transformations(StValidation.default_transformations) }
    let(:is_int_bp) { Integer }
    let(:is_maybe_int_bp) { Set[NilClass, Integer] }
    let(:is_int_array_bp) { [Integer] }
    let(:is_one_of_fruits_bp) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:regexp_bp) { ->(x) { !!(/abc/ =~ x) } }
    let(:is_bool_bp) { Set[TrueClass, FalseClass] }
    let(:is_user_bp) do
      {
        id: Integer,
        email: ->(x) { x.is_a?(String) && !!(x =~ /.+\@.+/) },
        admin: Set[TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits_bp,
        info: {
          phone: String,
          notes: Set[NilClass, String]
        }
      }
    end

    include_examples 'examples'
  end

  describe 'alternative1' do
    let(:factory) { StValidation.with_transformations(StValidation.alternative1) }
    let(:is_int_bp) { Integer }
    let(:is_maybe_int_bp) { Set[NilClass, Integer] }
    let(:is_bool_bp) { Set[TrueClass, FalseClass] }
    let(:is_int_array_bp) do
      is_int = factory.build(Integer)
      [Array, ->(x) { x.all?(&is_int) }]
    end
    let(:is_one_of_fruits_bp) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:regexp_bp) { ->(x) { !!(/abc/ =~ x) } }
    let(:is_user_bp) do
      {
        id: Integer,
        email: [String, ->(x) { x =~ /.+\@.+/ }],
        admin: Set[TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits_bp,
        info: {
          phone: String,
          notes: Set[NilClass, String]
        }
      }
    end

    include_examples 'examples'
  end

  describe 'alternative2' do
    let(:factory) { StValidation.with_transformations(StValidation.alternative2) }
    let(:is_int_bp) { Integer }
    let(:is_maybe_int_bp) { [:or, NilClass, Integer] }
    let(:is_int_array_bp) do
      is_int = factory.build(Integer)
      [:and, Array, ->(x) { x.all?(&is_int) }]
    end
    let(:is_bool_bp) { [:or, TrueClass, FalseClass] }
    let(:is_one_of_fruits_bp) { Set['apple', 'orange'].method(:include?).to_proc }
    let(:regexp_bp) { ->(x) { !!(x =~ /abc/) } }
    let(:is_user_bp) do
      {
        id: Integer,
        email: [:and, String, ->(x) { x =~ /.+\@.+/ }],
        admin: [:or, TrueClass, FalseClass],
        favourite_fruit: is_one_of_fruits_bp,
        info: {
          phone: String,
          notes: [:or, NilClass, String]
        }
      }
    end

    include_examples 'examples'
  end

  describe 'customised alternative2' do
    let(:factory) do
      StValidation
        .with_transformations(StValidation.alternative2)
        .with_extra_transformations(
          ->(bp, _) { bp == :bool ? [:or, TrueClass, FalseClass] : bp },
          ->(bp, _) { bp.is_a?(Regexp) ? ->(x) { !!(x =~ bp) } : bp },
          ->(bp, _) { bp.is_a?(Set) ? ->(x) { bp.include?(x) } : bp },
          lambda do |bp, f|
            return bp unless bp.is_a?(Array) && bp[0] == :array

            ->(x) { x.is_a?(Array) && x.all?(&f.build(bp[1])) }
          end
        )
    end

    let(:is_int_bp) { Integer }
    let(:is_maybe_int_bp) { [:or, NilClass, Integer] }
    let(:is_int_array_bp) { [:array, Integer] }
    let(:regexp_bp) { /abc/ }
    let(:is_bool_bp) { :bool }
    let(:is_one_of_fruits_bp) { Set['apple', 'orange'] }
    let(:is_user_bp) do
      {
        id: Integer,
        email: /.+\@.+/,
        admin: :bool,
        favourite_fruit: is_one_of_fruits_bp,
        info: {
          phone: String,
          notes: [:or, NilClass, String]
        }
      }
    end

    include_examples 'examples'
  end
end
