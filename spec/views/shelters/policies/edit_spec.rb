require "rails_helper"

RSpec.describe "shelters/policies/edit", type: :view do
  let(:shelter) { create(:shelter) }

  before do
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:shelter, shelter)
  end

  it "renders the title and subtitle" do
    render

    assert_select "h1", text: I18n.t("shelters.policies.edit.title")
    assert_select "p", text: I18n.t("shelters.policies.edit.subtitle")
  end

  it "renders the back link to the shelter dashboard" do
    render

    assert_select "a[href='#{shelter_dashboard_path(shelter_id: shelter)}']", text: I18n.t("shared.back")
  end

  it "submits to the policies path with PATCH" do
    render

    assert_select "form[action='#{shelter_policies_path(shelter_id: shelter)}'][method='post']" do
      assert_select "input[name='_method'][value='patch']"
    end
  end

  # Regression guard for AC-42-6: the grouped restyle must not change the
  # submitted field names — policy_params permits exactly these keys.
  it "preserves the adoption_policies field names" do
    render

    assert_select "input[name='shelter[adoption_policies][adoption_fee]']"
    assert_select "input[name='shelter[adoption_policies][fee_description]']"
    assert_select "input[name='shelter[adoption_policies][minimum_age]']"
    assert_select "input[name='shelter[adoption_policies][home_visit_required]']"
    assert_select "input[name='shelter[adoption_policies][fenced_yard_required]']"
    assert_select "input[name='shelter[adoption_policies][vet_reference_required]']"
    assert_select "textarea[name='shelter[adoption_policies][other_requirements]']"
  end

  it "renders the three grouped sections" do
    render

    assert_select "h2", text: I18n.t("shelters.policies.edit.groups.fee.title")
    assert_select "h2", text: I18n.t("shelters.policies.edit.groups.requirements.title")
    assert_select "h2", text: I18n.t("shelters.policies.edit.groups.other.title")
  end

  it "pre-fills existing values and checked state" do
    shelter.update!(adoption_policies: {
      adoption_fee: 150,
      minimum_age: 21,
      home_visit_required: true,
      other_requirements: "Must live within 50 miles"
    })

    render

    assert_select "input[name='shelter[adoption_policies][adoption_fee]'][value='150']"
    assert_select "input[name='shelter[adoption_policies][minimum_age]'][value='21']"
    assert_select "input[name='shelter[adoption_policies][home_visit_required]'][checked='checked']"
    assert_select "textarea[name='shelter[adoption_policies][other_requirements]']", text: "Must live within 50 miles"
  end

  it "renders the submit button" do
    render

    assert_select "input[type='submit'][value='#{I18n.t('shelters.policies.edit.submit')}']"
  end
end
