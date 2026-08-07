require "rails_helper"

RSpec.describe "shared/back_link", type: :view do
  it "renders a labeled back link to the given path" do
    render partial: "shared/back_link", locals: { path: "/en/dashboard", label: "Back to dashboard" }

    assert_select "a[href='/en/dashboard']", text: /Back to dashboard/
  end

  it "defaults the label to the shared back translation" do
    render partial: "shared/back_link", locals: { path: "/en/shelters" }

    assert_select "a[href='/en/shelters']", text: /#{Regexp.escape(I18n.t("shared.back"))}/
  end

  it "marks the chevron icon as decorative for screen readers" do
    render partial: "shared/back_link", locals: { path: "/en/shelters", label: "Back" }

    assert_select "a svg[aria-hidden='true']"
  end
end
