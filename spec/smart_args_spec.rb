require 'spec_helper'

module SmartArgs
  PreCondition = Struct.new(:name, :accepts) do
    def pass?(args)
      args.fetch(name).is_a?(accepts)
    end
  end

  def argument(name, accepts:)
    @preconditions ||= []
    @preconditions.push(PreCondition.new(name, accepts))
  end

  def method_added(method_name)
    @preconditions ||= []
    @module ||= Module.new
    self.prepend(@module)
    super

    if @preconditions.any?
      preconditions = @preconditions
      @module.send(:define_method, method_name) do |*args, **kwargs, &blk|
        raise ArgumentError unless preconditions.all? { |precondition| precondition.pass?(kwargs) }
        super(*args, **kwargs, &blk)
      end
      @preconditions = []
    end
  end
end

RSpec.describe SmartArgs do
  let(:dummy_object) do
    Class.new do
      extend SmartArgs

      argument :name, accepts: String
      def greet(name:)
        "Hello #{name}"
      end

      argument :title, accepts: String
      argument :last_name, accepts: String
      def greet_formally(title:, last_name:)
        "Hello #{title} #{last_name}"
      end

      def old?(age:)
        age > 100
      end

      argument :age, accepts: Integer
      def can_drink?(age:, money:)
        !!(age > 19 && money)
      end
      #
      # argument :age, accepts: String
      # def to_int(age:)
      #   age.to_i
      # end
    end
  end

  it "doesn't affect the method when provided with valid arguments" do
    expect(dummy_object.new.greet(name: "John")).to eq("Hello John")
  end

  it "raises an error when invoked with arguments of incorrect type" do
    expect { dummy_object.new.greet(name: 1) }.to raise_error(ArgumentError)
  end

  it "supports checking multiple arguments" do
    expect(dummy_object.new.greet_formally(title: "Mr.", last_name: "Doe")).to eq("Hello Mr. Doe")
  end

  it "raises an error if at least one argument check fails" do
    expect { dummy_object.new.greet_formally(title: 1, last_name: "Doe") }.to raise_error(ArgumentError)
    expect { dummy_object.new.greet_formally(title: "Mr.", last_name: 1) }.to raise_error(ArgumentError)
  end

  it "argument checks are only applied to methods that ask for them" do
    expect(dummy_object.new.old?(age: 1)).to eq(false)
  end

  it "argument checks apply only to the parameters they need to" do
    expect(dummy_object.new.can_drink?(age: 21, money: 1)).to eq(true)
    expect { dummy_object.new.can_drink?(age: "21", money: 1) }.to raise_error(ArgumentError)
  end

  it "argument checks different types depending on the method" do

  end
end
