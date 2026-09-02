require "rails_helper"

RSpec.describe "shelters/policies/show", type: :view do
  let(:shelter) { create(:shelter) }

  before do
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:shelter, shelter)
  end

  context "with configured policies" do
    before do
      shelter.update!(adoption_policies: {
        adoption_fee: 150,
        fee_description: "Covers vaccinations, spay/neuter, and microchipping",
        minimum_age: 21,
        home_visit_required: true,
        fenced_yard_required: false,
        vet_reference_required: "true",
        other_requirements: "Must live within 50 miles\nMust have previous pet experience"
      })
    end

    it "renders the title, description, and edit action" do
      render

      assert_select "h1", text: I18n.t("shelters.policies.show.title")
      assert_select "p", text: I18n.t("shelters.policies.show.description")
      assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}']",
                    text: I18n.t("shelters.policies.show.edit_policies")
    end

    it "renders the back link to the shelter dashboard" do
      render

      assert_select "a[href='#{shelter_dashboard_path(shelter_id: shelter)}']", text: I18n.t("shared.back")
    end

    it "renders the three grouped sections" do
      render

      assert_select "h2", text: I18n.t("shelters.policies.show.groups.fee.title")
      assert_select "h2", text: I18n.t("shelters.policies.show.groups.requirements.title")
      assert_select "h2", text: I18n.t("shelters.policies.show.groups.other.title")
    end

    it "renders the fee as currency and the fee description" do
      render

      assert_select "p", text: "$150.00"
      assert_select "p", text: "Covers vaccinations, spay/neuter, and microchipping"
    end

    it "renders the minimum age with a plus suffix" do
      render

      assert_select "p", text: I18n.t("shelters.policies.show.minimum_age_value", age: 21)
    end

    it "renders requirement chips for required and not-required booleans" do
      render

      assert_select "span", text: I18n.t("shelters.policies.show.required"), count: 2
      assert_select "span", text: I18n.t("shelters.policies.show.not_required"), count: 1
    end

    it "renders other requirements as a bulleted list" do
      render

      assert_select "li", text: "Must live within 50 miles"
      assert_select "li", text: "Must have previous pet experience"
    end
  end

  context "with partial policies" do
    before do
      shelter.update!(adoption_policies: { adoption_fee: 0 })
    end

    it "renders No fee and Not set placeholders instead of blank markup" do
      render

      assert_select "p", text: I18n.t("shelters.policies.show.no_fee")
      assert_select "p", text: I18n.t("shelters.policies.show.not_set"), minimum: 1
      assert_select "span", text: I18n.t("shelters.policies.show.not_set"), minimum: 3
    end
  end

  context "with a nil adoption fee but other fields set" do
    before do
      shelter.update!(adoption_policies: { fee_description: "Covers vaccinations" })
    end

    it "renders Not set for the fee amount" do
      render

      assert_select "section[aria-labelledby='policies-fee-title'] p",
                    text: I18n.t("shelters.policies.show.not_set"), count: 1
    end
  end

  context "with all requirements explicitly not required" do
    before do
      shelter.update!(adoption_policies: {
        home_visit_required: false,
        fenced_yard_required: false,
        vet_reference_required: false
      })
    end

    it "renders the grouped cards (not the empty state) with Not required chips" do
      render

      assert_select "h2", text: I18n.t("shelters.policies.show.groups.requirements.title")
      assert_select "span", text: I18n.t("shelters.policies.show.not_required"), count: 3
      assert_select "h2", text: I18n.t("shelters.policies.show.empty.title"), count: 0
    end
  end

  context "with an empty other_requirements string among set fields" do
    before do
      shelter.update!(adoption_policies: { adoption_fee: 100, other_requirements: "" })
    end

    it "renders Not set instead of an empty list" do
      render

      assert_select "section[aria-labelledby='policies-other-title'] p",
                    text: I18n.t("shelters.policies.show.not_set")
      assert_select "section[aria-labelledby='policies-other-title'] li", count: 0
    end
  end

  context "with a very long other requirement" do
    before do
      shelter.update!(adoption_policies: {
        adoption_fee: 100,
        other_requirements: "Adopters must live within a reasonable distance of the shelter and be prepared to provide a safe, loving, and permanent home for the animal for its entire natural life"
      })
    end

    it "renders the long text with a wrapping-safe container" do
      render

      assert_select "section[aria-labelledby='policies-other-title'] li span[class~='min-w-0']",
                    text: /Adopters must live within/
    end
  end

  context "with no policies configured" do
    it "renders the intentional empty state with the edit CTA" do
      render

      assert_select "h2", text: I18n.t("shelters.policies.show.empty.title")
      assert_select "p", text: I18n.t("shelters.policies.show.empty.description")
      assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}']",
                    text: I18n.t("shelters.policies.show.edit_policies")
    end
  end
end
