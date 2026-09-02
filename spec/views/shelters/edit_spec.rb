require "rails_helper"

RSpec.describe "shelters/edit", type: :view do
  let(:shelter) { create(:shelter) }

  before do
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:shelter, shelter)
  end

  it "renders all information groups with their headings and helper lines" do
    render

    assert_select "h2", text: I18n.t("shelters.edit.basic_info_title")
    assert_select "h2", text: I18n.t("shelters.edit.media_title")
    assert_select "h2", text: I18n.t("shelters.edit.contact_location_title")
    assert_select "h2", text: I18n.t("shelters.edit.public_profile_title")
    assert_select "h2", text: I18n.t("shelters.edit.configuration_title")
    assert_select "h2", text: I18n.t("shelters.edit.informational_title")
  end

  it "keeps every editable field in the form exactly once" do
    render

    %i[name street city state zip phone website description hours].each do |field|
      assert_select "#shelter_#{field}", count: 1
    end
    assert_select "#shelter_logo", count: 1
    assert_select "#shelter_cover_image", count: 1
    assert_select "#shelter_profile_picture", count: 1
  end

  it "posts as multipart so image uploads reach Active Storage" do
    render

    assert_select "form[enctype='multipart/form-data']", count: 1
    assert_select "input[type=file][accept='image/jpeg,image/png,image/webp']", count: 3
  end

  it "renders media placeholders and upload hints when no images are attached" do
    render

    assert_select "span", text: I18n.t("shelters.edit.logo_placeholder")
    assert_select "span", text: I18n.t("shelters.edit.cover_placeholder")
    assert_select "span", text: I18n.t("shelters.edit.profile_placeholder")
    assert_includes rendered, I18n.t("shelters.edit.media_field.upload_hint")
    expect(rendered).not_to include(I18n.t("shelters.edit.media_field.replace_hint"))
  end

  it "renders previews and replace hints for attached images" do
    shelter.logo.attach(io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")), filename: "logo.jpg", content_type: "image/jpeg")

    render

    assert_includes rendered, I18n.t("shelters.edit.media_field.replace_hint")
    assert_includes rendered, I18n.t("shelters.edit.logo_preview_alt", name: shelter.name)
  end

  it "renders the save and cancel actions" do
    render

    assert_select "input[type=submit][value='#{I18n.t('shelters.edit.submit')}']", count: 1
    assert_select "a", text: I18n.t("shelters.edit.cancel"), count: 1
  end

  it "renders a back link resolving through safe_back_path to the dashboard" do
    render

    assert_select "a[href='#{shelter_dashboard_path(shelter_id: shelter)}']", text: I18n.t("shared.back")
  end

  it "renders the error summary when the shelter is invalid" do
    shelter.errors.add(:name, "can't be blank")

    render

    assert_select "[role='alert']" do
      assert_select "li", text: "Name can't be blank"
    end
  end

  it "renders read-only shelter metadata instead of editable fields" do
    render

    assert_select "dt", text: I18n.t("shelters.edit.shelter_id_label")
    assert_select "dt", text: I18n.t("shelters.edit.member_since_label")
    assert_select "dd", text: shelter.id.to_s
  end

  it "marks fields with errors and renders inline messages" do
    shelter.errors.add(:name, "can't be blank")
    shelter.errors.add(:name, "is too short")

    render

    assert_select "#shelter_name.border-danger", count: 1
    assert_select "p.text-danger", text: "can't be blank"
  end

  it "renders the species checkboxes and status radio buttons" do
    render

    assert_select "input[type=checkbox][name='shelter[species_served][]']", count: 3
    assert_select "input[type=radio][name='shelter[status]']", count: 2
  end

  it "shows a 'not set' hint when species_served is empty" do
    shelter.species_served = []

    render

    assert_includes rendered, I18n.t("shelters.edit.species_not_set")
  end

  it "aligns city/state and zip/phone pairs on a responsive grid" do
    render

    assert_select ".grid.grid-cols-1.sm\\:grid-cols-2.gap-4", minimum: 3
  end

  it "renders localized strings in Spanish" do
    I18n.with_locale(:es) do
      render

      assert_includes rendered, I18n.t("shelters.edit.basic_info_title", locale: :es)
      assert_includes rendered, I18n.t("shelters.edit.media_field.upload_hint", locale: :es)
    end
  end
end
