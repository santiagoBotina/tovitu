require "rails_helper"

RSpec.describe Ai::DocumentChunk, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:ai_document) }
  end
end
