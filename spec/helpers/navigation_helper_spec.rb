require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  describe "#safe_back_path" do
    it "returns the fallback path when no back_to param is present" do
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "returns the back_to path when it is an internal, recognized route" do
      helper.params[:back_to] = "/en/adoption_requests/1"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/adoption_requests/1")
    end

    it "supports shelter-scoped back paths" do
      helper.params[:back_to] = "/en/shelter/adoption_requests/1"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/shelter/adoption_requests/1")
    end

    it "strips query strings only for validation, keeping them in the result" do
      helper.params[:back_to] = "/en/adoption_requests/1?tab=timeline"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/adoption_requests/1?tab=timeline")
    end

    it "rejects protocol-relative URLs" do
      helper.params[:back_to] = "//evil.com"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "rejects scheme-prefixed external URLs" do
      helper.params[:back_to] = "https://evil.com"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "rejects javascript: URLs" do
      helper.params[:back_to] = "javascript:alert(1)"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "rejects backslash-obfuscated protocol-relative URLs" do
      helper.params[:back_to] = "/\\evil.com"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "rejects paths that do not match any route" do
      helper.params[:back_to] = "/en/does/not/exist"
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end

    it "rejects blank back_to values" do
      helper.params[:back_to] = ""
      expect(helper.safe_back_path("/en/pets")).to eq("/en/pets")
    end
  end
end
