require "rails_helper"

RSpec.describe Shelters::UpdateProfile do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:admin) { create(:user, :verified, shelter: shelter, role: "shelter_admin") }

    context "by shelter admin" do
      it "updates text fields" do
        result = described_class.call(shelter: shelter, user: admin, params: { name: "New Name" })
        expect(result).to be_success
        expect(shelter.reload.name).to eq("New Name")
      end
    end

    context "by non-admin" do
      let(:staff) { create(:user, :verified, shelter: shelter, role: "staff") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: staff, params: { name: "New Name" })
        expect(result).to be_failure
      end
    end

    context "by admin from different shelter" do
      let(:other_shelter) { create(:shelter) }
      let(:other_admin) { create(:user, :verified, shelter: other_shelter, role: "shelter_admin") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, user: other_admin, params: { name: "New Name" })
        expect(result).to be_failure
      end
    end

    context "with invalid params" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, user: admin, params: { name: "" })
        expect(result).to be_failure
      end
    end
  end
end
