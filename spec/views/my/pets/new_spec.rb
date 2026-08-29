require "rails_helper"

RSpec.describe "my/pets/new", type: :view do
  let(:pet) { build(:pet) }

  before do
    assign(:pet, pet)
  end

  it "renders every select with the shared select-control class" do
    render

    assert_select "select.select-control", count: 4
  end

  it "keeps the left padding utility so text alignment is unchanged" do
    render

    assert_select "select.select-control[class~='pl-4']", count: 4
  end
end
