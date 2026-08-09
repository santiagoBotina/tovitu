require "rails_helper"

RSpec.describe "shared/auth_brand", type: :view do
  it "renders the official Tovitu logo mark (decorative, aria-hidden)" do
    render partial: "shared/auth_brand"

    assert_select "img[aria-hidden='true'][alt='']"
  end

  it "renders the Tovitu wordmark in the display face with the primary color" do
    render partial: "shared/auth_brand"

    assert_select "p[class~='font-display'][class~='text-primary-600']", text: "Tovitu"
  end

  it "lays out the lockup as a vertical, centered brand moment" do
    render partial: "shared/auth_brand"

    assert_select "div[class~='flex-col'][class~='items-center']"
    assert_select "div[class~='flex-col'] > img"
    assert_select "div[class~='flex-col'] > p", text: "Tovitu"
  end

  it "keeps the same mark sizing convention as the navbar/sidebar (w-14 h-14)" do
    render partial: "shared/auth_brand"

    assert_select "img[class~='w-14'][class~='h-14']"
  end
end
