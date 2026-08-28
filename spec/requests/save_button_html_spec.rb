require "rails_helper"

RSpec.describe "Save button HTML inspection" do
  it "renders the optimistic favorite-toggle form for signed-in users" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path, params: { session: { email: user.email, password: "password123" } }
    pet = create(:pet)

    get pet_path(pet)

    body = response.body
    # Circle heart control
    expect(body).to include(%(id="save-button-#{pet.id}"))
    expect(body).to include('data-controller="favorite-toggle"')
    expect(body).to include("data-favorite-toggle-pet-id-value=\"#{pet.id}\"")
    expect(body).to include("data-favorite-toggle-saved-value=\"false\"")
    expect(body).to include("data-action=\"submit-&gt;favorite-toggle#toggle\"")
    expect(body).to include("data-favorite-toggle-target=\"button\"")
    expect(body).to include("data-favorite-toggle-target=\"icon\"")
    expect(body).to include("aria-pressed=\"false\"")
    # Labeled sidebar control
    expect(body).to include(%(id="save-button-#{pet.id}-label"))
    expect(body).to include("data-favorite-toggle-target=\"label\"")
  end

  it "renders the DELETE method for an already-saved pet" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path, params: { session: { email: user.email, password: "password123" } }
    pet = create(:pet)
    create(:saved_pet, user: user, pet: pet)

    get pet_path(pet)

    body = response.body
    expect(body).to include("data-favorite-toggle-saved-value=\"true\"")
    expect(body).to include('name="_method"')
    expect(body).to include('value="delete"')
    expect(body).to include("aria-pressed=\"true\"")
  end
end