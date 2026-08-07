require "rails_helper"

RSpec.describe "shared/verified_badge", type: :view do
  it "renders a squared (non-pill) badge with the success palette" do
    render partial: "shared/verified_badge", locals: { label: "Verified" }

    assert_select "span[role='status'][class~='rounded-lg'][class~='bg-success/10'][class~='text-success']"
    assert_select "span svg[aria-hidden='true']"
  end

  it "defaults the label to the shared verified translation" do
    render partial: "shared/verified_badge"

    assert_select "span[aria-label='#{I18n.t('shared.verified_badge')}']"
  end

  it "accepts a custom label and extra classes" do
    render partial: "shared/verified_badge", locals: { label: "WhatsApp verified", extra_class: "ml-2" }

    assert_select "span[aria-label='WhatsApp verified'][class~='ml-2']"
  end

  it "is a live status region for screen readers" do
    render partial: "shared/verified_badge", locals: { label: "Verified" }

    assert_select "span[role='status'][aria-label='Verified']"
  end
end
