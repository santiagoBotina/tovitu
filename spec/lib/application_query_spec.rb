require "rails_helper"

RSpec.describe ApplicationQuery do
  describe ".call" do
    it "instantiates and calls" do
      instance = instance_double(described_class)
      expect(described_class).to receive(:new).with(foo: "bar").and_return(instance)
      expect(instance).to receive(:call).and_return("result")
      expect(described_class.call(foo: "bar")).to eq("result")
    end
  end

  describe "#call" do
    it "raises NotImplementedError" do
      expect { described_class.new.call }.to raise_error(NotImplementedError)
    end
  end
end
