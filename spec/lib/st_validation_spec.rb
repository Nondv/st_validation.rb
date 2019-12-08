require 'spec_helper'
require_relative '../../lib/st_validation'

RSpec.describe StValidation do
  def build(*args)
    StValidation.build(*args)
  end

  it 'uses classes, sets, arrays and hashes for definiton' do
    build(
      int: Integer,
      maybe_int: Set[Integer, NilClass],
      bool: Set[TrueClass, FalseClass],
      array_int: [Integer],
      maybe_array_int: Set[[Integer], NilClass]
    )
  end

  it 'raises exception when something irregular provided' do
    error_class = StValidation::InvalidBlueprintError

    expect { build(obj: Object.new) }.to raise_error(error_class)
    expect { build(key: :int) }.to raise_error(error_class)
  end

  describe 'atom-blueprints are' do
    it 'procs' do
      validator = build(->(x) { x > 10 })
      expect(validator.call(11)).to be true
      expect(validator.call(9)).to be false
    end

    it 'classes (transformed into class check proc)' do
      validator = build(String)
      expect(validator.call('123')).to be true
      expect(validator.call(123)).to be false
      expect(validator.call(nil)).to be false
    end

    it 'validators (like proc but has its own class)' do
      less_than_validator_klass = Class.new(StValidation::AbstractValidator) do
        def initialize(number)
          @number = number
        end

        def call(value)
          value.is_a?(Numeric) && value < @number
        end
      end

      validator = build(less_than_validator_klass.new(5))
      expect(validator.call(4)).to be true
      expect(validator.call(5)).to be false
      expect(validator.call(4.9999)).to be true
      expect(validator.call('4')).to be false
    end
  end

  it "is a bit weird for booleans since there's no Bool class in Ruby" do
    validator = build(Set[TrueClass, FalseClass])
    expect(validator.call(true)).to be true
    expect(validator.call(false)).to be true
    expect(validator.call(nil)).to be false
    expect(validator.call({})).to be false
  end

  describe 'complex blueprints' do
    describe 'array' do
      it 'describes array of elements matching specific blueprint' do
        validator = build([Integer])
        expect(validator.call(123)).to be false
        expect(validator.call([123])).to be true
        expect(validator.call([123.0])).to be false
        expect(validator.call([])).to be true
        expect(validator.call(1..1000)).to be false
        expect(validator.call((1..1000).to_a)).to be true
      end

      it 'also accepts complex blueprints' do
        multiclass = build([Set[Integer, String]])
        expect(multiclass.call([])).to be true
        expect(multiclass.call([1, 2, 3])).to be true
        expect(multiclass.call(%w[1 2 3])).to be true
        expect(multiclass.call([1, '2', 3])).to be true

        arrays = build([[Integer]])
        expect(arrays.call([])).to be true
        expect(arrays.call([1, 2, 3])).to be false
        expect(arrays.call([[1, 2, 3]])).to be true
        expect(arrays.call([[1], [2], [3]])).to be true

        hashes = build([{ x: Integer, y: Set[NilClass, String] }])
        expect(hashes.call([])).to be true
        expect(hashes.call([{}])).to be false
        expect(hashes.call([{ x: 1 }])).to be true
        expect(hashes.call([{ x: 1, y: '1' }])).to be true
      end

      it 'throws error when empty' do
        expect { build([]) }
          .to raise_error(StValidation::InvalidBlueprintError)
      end
    end

    describe 'set' do
      it 'checks if a value matches any of blueprints' do
        validator = build(Set[NilClass, Integer, String])
        expect(validator.call(123)).to be true
        expect(validator.call('123')).to be true
        expect(validator.call(nil)).to be true

        expect(validator.call(x: :abc)).to be false
        expect(validator.call(x: Set[NilClass, Integer, String])).to be false
      end

      it 'also accepts complex blueprints' do
        validator = build(Set[NilClass, { a: Integer }, [Integer]])

        expect(validator.call(nil)).to be true
        expect(validator.call([1, 2, 3])).to be true
        expect(validator.call(%w[1 2 3])).to be false
        expect(validator.call([])).to be true

        expect(validator.call(a: 123)).to be true
        expect(validator.call(a: '123')).to be false
        expect(validator.call(a: 123, b: nil)).to be false
        expect(validator.call(a: nil)).to be false
      end

      it 'throws error when empty' do
        expect { build(Set[]) }
          .to raise_error(StValidation::InvalidBlueprintError)
      end
    end

    describe 'hash' do
      it 'checks if keys match the blueprint' do
        validator = build(x: String,
                          y: ->(x) { x.is_a?(Integer) && x < 5 },
                          z: NilClass)

        expect(validator.call(x: '123', y: 4, z: nil)).to be true
        expect(validator.call(x: '123', y: 4)).to be true
        expect(validator.call(x: 4, y: 4)).to be false
        expect(validator.call(x: '123', y: '123')).to be false
      end

      it 'forces a hash to match all keys (no extras)' do
        validator = build(x: Integer, y: String)
        expect(validator.call(x: 1, y: '5')).to be true
        expect(validator.call(y: '5')).to be false
        expect(validator.call(x: 1, z: '5')).to be false
      end
    end
  end

  describe 'additional transformations' do
    it 'allows to tinker factory behaviour' do
      factory = StValidation.with_extra_transformations(
        ->(bp, _factory) { bp == :int ? Integer : bp },
        lambda do |blueprint, _factory|
          return blueprint unless blueprint == :positive

          ->(value) { value.is_a?(Integer) && value.positive? }
        end
      )

      validator = factory.build(
        id: :int,
        age: :positive,
        fav_numbers: [:int]
      )

      expect(validator.call(id: 123, age: 18, fav_numbers: [1, 2, 3])).to be true
      expect(validator.call(id: 123, age: -1, fav_numbers: [1, 2, 3])).to be false
      expect(validator.call(id: 123, age: 18, fav_numbers: [1, '2', 3])).to be false
    end
  end

  describe '#explain' do
    it 'is supposed to work the same as #call but returning some info about invalid data' do
      validator = StValidation.build(
        id: Integer,
        email: String,
        info: {
          name: String,
          age: Set[NilClass, Integer],
          favourite_food: [String]
        }
      )

      result = validator.explain(
        id: '123',
        email: 'user@example.com',
        info: {
          name: 'John',
          age: '18',
          favourite_food: ['apple', :pies],
          notes: 'brother of Jane Doe'
        }
      )

      expect(result).to(
        eq(id: 'expected Integer got String',
           info: { age: ['expected NilClass got String',
                         'expected Integer got String'],
                   favourite_food: [nil, 'expected String got Symbol'],
                   notes: 'extra key detected' })
      )
    end

    it 'shows source location for procs' do
      is_age = ->(x) { x > 0 }
      validator = StValidation.build(
        id: Integer,
        age: is_age
      )

      result = validator.explain(id: 123, age: -5)
      expect(result).to eq(age: is_age.source_location)
    end

    it 'suppresses inner validators errors' do
      is_valid_age = ->(x) { x > 0 }
      validator = StValidation.build(
        id: Integer,
        age: is_valid_age
      )

      result = validator.explain(id: '123', age: '18')
      expect(result[:age]).to start_with('#explain failed with ArgumentError')
    end
  end
end
