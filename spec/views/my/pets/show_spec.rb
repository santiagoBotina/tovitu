require "rails_helper"

RSpec.describe "my/pets/show", type: :view do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter, name: "Fido") }

  before do
    # signed_in? is a controller helper_method, not a view helper — define it
    # on the view so the page renders the signed-out save button path.
    view.singleton_class.define_method(:signed_in?) { false }
    # Locale-scoped routes bind positional args (my_pet_path(@pet), etc.) to the
    # :locale segment unless the test controller provides default_url_options.
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }

    # NOTE: the controller currently assigns a raw Pet, but the view calls
    # presenter methods (species_label, age_display, ...) which a raw Pet does
    # not respond to — a pre-existing bug tracked separately from plan 39.
    # Wrapping in the presenter documents the intended contract so the compact
    # status select markup stays covered.
    assign(:pet, PetPresenter.new(pet))
    assign(:incoming_requests, [])
  end

  it "renders the compact status select with the shared chevron and preserved padding" do
    render

    assert_select "select.select-control[class~='pl-4'][class~='py-2.5']", count: 1
  end
end
