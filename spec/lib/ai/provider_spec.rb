require "rails_helper"

RSpec.describe Ai::Provider do
  describe "#call" do
    let(:prompt) { "Tell me about dogs" }
    let(:response_double) { instance_double(HTTParty::Response, success?: true, parsed_response: parsed, code: 200) }
    let(:parsed) { { "choices" => [ { "message" => { "content" => '{"text": "Dogs are great"}' } } ] } }

    before do
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("test-key")
    end

    context "with successful API response" do
      before do
        allow(HTTParty).to receive(:post).and_return(response_double)
      end

      it "returns the content from the API" do
        result = described_class.call(prompt: prompt)
        expect(result).to eq('{"text": "Dogs are great"}')
      end
    end

    context "with API error" do
      let(:error_response) do
        instance_double(HTTParty::Response, success?: false, parsed_response: { "error" => { "message" => "Bad request" } }, body: "error body", code: 400)
      end

      before do
        allow(HTTParty).to receive(:post).and_return(error_response)
      end

      it "raises ProviderError" do
        expect {
          described_class.call(prompt: prompt)
        }.to raise_error(Ai::ProviderError, /OpenAI API error/)
      end
    end

    context "with network error" do
      before do
        allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new("connection failed"))
      end

      it "raises ProviderError" do
        expect {
          described_class.call(prompt: prompt)
        }.to raise_error(Ai::ProviderError, /request failed/)
      end
    end
  end
end
