require "rails_helper"

RSpec.describe Result do
  describe ".success" do
    it "creates a successful result" do
      result = described_class.success(id: 1)
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.data).to eq(id: 1)
      expect(result.errors).to eq([])
      expect(result.error_code).to be_nil
    end

    it "creates a successful result without data" do
      result = described_class.success
      expect(result).to be_success
      expect(result.data).to be_nil
    end
  end

  describe ".failure" do
    it "creates a failed result with errors" do
      result = described_class.failure([ "Error message" ])
      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.errors).to eq([ "Error message" ])
    end

    it "creates a failed result with error code" do
      result = described_class.failure("Error", error_code: :not_found)
      expect(result.error_code).to eq(:not_found)
    end

    it "wraps single error string in array" do
      result = described_class.failure("Single error")
      expect(result.errors).to eq([ "Single error" ])
    end

    it "freezes the result" do
      result = described_class.success
      expect(result).to be_frozen
    end
  end

  describe "#on_success" do
    it "yields data when successful" do
      result = described_class.success(name: "test")
      yielded = nil
      result.on_success { |data| yielded = data }
      expect(yielded).to eq(name: "test")
    end

    it "does not yield when failed" do
      result = described_class.failure("error")
      yielded = false
      result.on_success { yielded = true }
      expect(yielded).to be false
    end

    it "returns self for chaining" do
      result = described_class.success
      expect(result.on_success { }).to eq(result)
    end
  end

  describe "#on_failure" do
    it "yields errors and error_code when failed" do
      result = described_class.failure("error", error_code: :bad_request)
      yielded_errors = nil
      yielded_code = nil
      result.on_failure { |errors, code| yielded_errors = errors; yielded_code = code }
      expect(yielded_errors).to eq([ "error" ])
      expect(yielded_code).to eq(:bad_request)
    end

    it "does not yield when successful" do
      result = described_class.success
      yielded = false
      result.on_failure { yielded = true }
      expect(yielded).to be false
    end

    it "returns self for chaining" do
      result = described_class.failure("error")
      expect(result.on_failure { }).to eq(result)
    end
  end
end
