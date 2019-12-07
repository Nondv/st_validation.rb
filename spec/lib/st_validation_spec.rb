require 'spec_helper'
require 'st_validation'

RSpec.describe StValidation do
  def build(*args)
    described_class.build(*args)
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
end
