require "rails_helper"

RSpec.describe "shelters/dashboard/show", type: :view do
  let(:shelter) { create(:shelter) }
  let(:admin_policy) { double(manage?: true, staff_index?: true, manage_policies?: true) }
  let(:administrator_policy) { double(manage?: false, staff_index?: true, manage_policies?: true) }
  let(:staff_policy) { double(manage?: false, staff_index?: false, manage_policies?: false) }

  before do
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:shelter, shelter)
  end

  def stub_policy(policy)
    view.singleton_class.send(:define_method, :policy) { |_record| policy }
  end

  def assign_counts(overrides = {})
    assign(:total_pets, overrides.fetch(:total_pets, 0))
    assign(:adoptable_pets, overrides.fetch(:adoptable_pets, 0))
    assign(:pending_requests, overrides.fetch(:pending_requests, 0))
    assign(:in_review_requests, overrides.fetch(:in_review_requests, 0))
    assign(:active_adoptions, overrides.fetch(:active_adoptions, 0))
    assign(:total_requests_count, overrides.fetch(:total_requests_count, 0))
    assign(:pending_count, overrides.fetch(:pending_count, overrides.fetch(:pending_requests, 0)))
    assign(:recent_activity, overrides.fetch(:recent_activity, []))
    assign(:pets_needing_attention, overrides.fetch(:pets_needing_attention, []))
    assign(:staff_count, overrides.fetch(:staff_count, 1))
    assign(:staff_members, overrides.fetch(:staff_members, []))
  end

  describe "header / identity" do
    it "renders a personalized title with an initials avatar when no logo is attached" do
      assign_counts(total_pets: 0)
      stub_policy(staff_policy)

      render

      assert_select "h1", text: /#{Regexp.escape(I18n.t("shelters.dashboard.show.title", name: shelter.name))}/
      assert_select "h1 span", text: shelter.name.first.upcase
      assert_select "h1 img", count: 0
    end

    it "renders the shelter logo when one is attached" do
      shelter.logo.attach(io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")), filename: "logo.jpg", content_type: "image/jpeg")
      assign_counts(total_pets: 1)
      stub_policy(staff_policy)

      render

      assert_select "h1 img[alt='']", count: 1
    end

    it "renders the empty-shelter subtitle when there are no pets" do
      assign_counts(total_pets: 0)
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.subtitle_empty")
    end

    it "renders the pending-review subtitle with counts when requests are pending" do
      assign_counts(total_pets: 2, adoptable_pets: 2, pending_requests: 3, pending_count: 3)
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.subtitle_pending", count: 3)
    end

    it "renders the singular pending-review subtitle when exactly one request is pending" do
      assign_counts(total_pets: 2, adoptable_pets: 2, pending_requests: 1, pending_count: 1)
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.subtitle_pending", count: 1)
    end

    it "renders the active subtitle with counts otherwise" do
      assign_counts(total_pets: 2, adoptable_pets: 2, active_adoptions: 1)
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.subtitle", adoptable: 2, active: 1)
    end
  end

  describe "metrics" do
    before do
      assign_counts(
        total_pets: 4,
        adoptable_pets: 3,
        pending_requests: 2,
        pending_count: 2,
        in_review_requests: 1,
        active_adoptions: 0,
        total_requests_count: 3
      )
      stub_policy(staff_policy)
      render
    end

    it "renders each metric with its label and real count" do
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.adoptable_pets")
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.pending_requests")
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.in_review")
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.active_adoptions")
      assert_select "p.font-display.text-3xl", text: "3", count: 1
      assert_select "p.font-display.text-3xl", text: "2", count: 1
      assert_select "p.font-display.text-3xl", text: "1", count: 1
    end

    it "renders a neutral hint for zero-value metrics" do
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.active_adoptions_hint_zero")
    end

    it "links each metric card to its management screen" do
      assert_select "a[href='#{shelter_pets_path}']", count: 2
      assert_select "a[href='#{shelter_adoption_requests_path(status: "pending")}']", count: 1
      assert_select "a[href='#{shelter_adoption_requests_path(status: "in_validation")}']", count: 1
      assert_select "a[href='#{shelter_adoption_requests_path(status: "accepted")}']", count: 1
    end
  end

  describe "empty shelter hero" do
    it "shows the welcome hero with an add-pet CTA instead of the metrics grid" do
      assign_counts(total_pets: 0, total_requests_count: 0)
      stub_policy(staff_policy)

      render

      assert_select "h2", text: I18n.t("shelters.dashboard.show.empty_state.title", name: shelter.name)
      assert_select "p", text: I18n.t("shelters.dashboard.show.empty_state.description")
      assert_select "a[href='#{new_shelter_pet_path}']", text: I18n.t("shelters.dashboard.show.empty_state.primary_cta")
      assert_select "p", text: I18n.t("shelters.dashboard.show.pipeline.adoptable_pets"), count: 0
    end

    it "offers the policies action to admins and the public page to staff" do
      assign_counts(total_pets: 0, total_requests_count: 0)
      stub_policy(admin_policy)

      render

      assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}']",
                    text: I18n.t("shelters.dashboard.show.empty_state.secondary_cta_policies")
    end

    it "offers the public page link to staff instead of the policies action" do
      assign_counts(total_pets: 0, total_requests_count: 0)
      stub_policy(staff_policy)

      render

      assert_select "a[href='#{shelter_path(shelter)}']",
                    text: I18n.t("shelters.dashboard.show.empty_state.secondary_cta_page")
      assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}']", count: 0
    end
  end

  describe "pending alert bar" do
    it "renders the alert with a review action when requests are pending" do
      assign_counts(total_pets: 1, adoptable_pets: 1, pending_requests: 2, pending_count: 2)
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.alert_bar", count: 2)
      assert_select "a[href='#{shelter_adoption_requests_path}']", text: I18n.t("shelters.dashboard.show.alert_cta")
      assert_select "div[role='status']", count: 1
    end

    it "is hidden when nothing is pending" do
      assign_counts(total_pets: 1, adoptable_pets: 1, pending_requests: 0, pending_count: 0)
      stub_policy(staff_policy)

      render

      assert_select "a", text: I18n.t("shelters.dashboard.show.alert_cta"), count: 0
      assert_select "div[role='status']", count: 0
    end
  end

  describe "recent activity" do
    let(:pet) { create(:pet, shelter: shelter) }
    let(:request) { create(:adoption_request, pet: pet, shelter: shelter) }

    it "renders activity items with a direct link to the request" do
      assign_counts(
        total_pets: 1,
        adoptable_pets: 1,
        recent_activity: [ request ],
        staff_count: 2,
        staff_members: shelter.users.limit(5)
      )
      stub_policy(staff_policy)

      render

      assert_select "p", text: I18n.t("shelters.dashboard.show.activity.event_new_application",
                                      adopter: request.adopter.name, pet: pet.name)
      assert_select "a[href='#{shelter_adoption_request_path(request)}']", count: 1
    end

    it "links to the full activity list when there are five items" do
      requests = 5.times.map { create(:adoption_request, pet: pet, shelter: shelter) }
      assign_counts(total_pets: 1, adoptable_pets: 1, recent_activity: requests)
      stub_policy(staff_policy)

      render

      assert_select "a[href='#{shelter_adoption_requests_path}']", text: I18n.t("shelters.dashboard.show.activity.view_all")
    end

    it "does not link to the full activity list when there are fewer than five items" do
      requests = 3.times.map { create(:adoption_request, pet: pet, shelter: shelter) }
      assign_counts(total_pets: 1, adoptable_pets: 1, recent_activity: requests)
      stub_policy(staff_policy)

      render

      assert_select "a[href='#{shelter_adoption_requests_path}']", text: I18n.t("shelters.dashboard.show.activity.view_all"), count: 0
    end

    it "renders a helpful empty state with an add-pet CTA" do
      assign_counts(total_pets: 0)
      stub_policy(staff_policy)

      render

      assert_select "h3", text: I18n.t("shelters.dashboard.show.activity.empty_title")
      assert_select "p", text: I18n.t("shelters.dashboard.show.activity.empty")
      assert_select "a[href='#{new_shelter_pet_path}']", text: I18n.t("shelters.dashboard.show.activity.empty_cta")
    end
  end

  describe "pets needing attention" do
    let(:pet) { create(:pet, shelter: shelter, description: nil) }

    it "renders incomplete pets with missing-field badges and edit links" do
      assign_counts(
        total_pets: 1,
        adoptable_pets: 1,
        pets_needing_attention: [ { pet: pet, missing: [ :photo, :description ] } ]
      )
      stub_policy(staff_policy)

      render

      assert_select "h2", text: I18n.t("shelters.dashboard.show.attention.title")
      assert_select "span", text: I18n.t("shelters.dashboard.show.attention.missing_photo")
      assert_select "span", text: I18n.t("shelters.dashboard.show.attention.missing_description")
      assert_select "a[href='#{edit_shelter_pet_path(id: pet.id)}']", text: /#{pet.name}/
    end

    it "is hidden when every pet profile is complete" do
      assign_counts(total_pets: 1, adoptable_pets: 1, pets_needing_attention: [])
      stub_policy(staff_policy)

      render

      assert_select "h2", text: I18n.t("shelters.dashboard.show.attention.title"), count: 0
    end
  end

  describe "quick actions" do
    before { stub_policy(policy) }

    context "as a staff member" do
      let(:policy) { staff_policy }

      it "promotes add-pet and review-applications and hides admin-gated actions" do
        assign_counts(total_pets: 1, adoptable_pets: 1)

        render

        assert_select "a[href='#{new_shelter_pet_path}']", text: I18n.t("shelters.dashboard.show.quick_actions.add_pet.title")
        assert_select "a[href='#{shelter_adoption_requests_path}']", text: I18n.t("shelters.dashboard.show.quick_actions.review_apps.title")
        assert_select "a[href='#{shelter_pets_path}']", text: /#{I18n.t("shelters.dashboard.show.quick_actions.manage_pets.title")}/
        assert_select "a", text: I18n.t("shelters.dashboard.show.quick_actions.manage_team.title"), count: 0
        assert_select "a", text: I18n.t("shelters.dashboard.show.quick_actions.policies.title"), count: 0
        assert_select "a", text: I18n.t("shelters.dashboard.show.quick_actions.profile.title"), count: 0
        expect(rendered).not_to include(shelter_staff_index_path(shelter_id: shelter))
        expect(rendered).not_to include(edit_shelter_policies_path(shelter_id: shelter))
      end
    end

    context "as an admin (owner)" do
      let(:policy) { admin_policy }

      it "renders admin-gated actions with correct destinations" do
        assign_counts(total_pets: 1, adoptable_pets: 1)

        render

        assert_select "a[href='#{shelter_staff_index_path(shelter_id: shelter)}'] p", text: I18n.t("shelters.dashboard.show.quick_actions.manage_team.title")
        assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}'] p", text: I18n.t("shelters.dashboard.show.quick_actions.policies.title")
        assert_select "a[href='#{edit_shelter_path(id: shelter)}'] p", text: I18n.t("shelters.dashboard.show.quick_actions.profile.title")
      end
    end

    context "as an administrator" do
      let(:policy) { administrator_policy }

      it "sees staff and policies but not owner-only profile management" do
        assign_counts(total_pets: 1, adoptable_pets: 1)

        render

        assert_select "a[href='#{shelter_staff_index_path(shelter_id: shelter)}'] p", text: I18n.t("shelters.dashboard.show.quick_actions.manage_team.title")
        assert_select "a[href='#{edit_shelter_policies_path(shelter_id: shelter)}'] p", text: I18n.t("shelters.dashboard.show.quick_actions.policies.title")
        assert_select "a", text: I18n.t("shelters.dashboard.show.quick_actions.profile.title"), count: 0
        expect(rendered).not_to include(edit_shelter_path(id: shelter))
      end
    end
  end

  describe "team status" do
    let(:members) { create_list(:user, 2, :verified, :onboarding_completed, shelter: shelter) }

    it "renders team avatars when there are two or more members" do
      assign_counts(total_pets: 1, adoptable_pets: 1, staff_count: 2, staff_members: members)
      stub_policy(staff_policy)

      render

      assert_select "h2", text: I18n.t("shelters.dashboard.show.team.title")
    end

    it "shows the +N overflow for teams larger than five" do
      members = create_list(:user, 6, :verified, :onboarding_completed, shelter: shelter)
      assign_counts(total_pets: 1, adoptable_pets: 1, staff_count: 6, staff_members: members.first(5))
      stub_policy(staff_policy)

      render

      assert_select "span", text: "+1"
      assert_select "span", text: I18n.t("shelters.dashboard.show.team.more", count: 1)
    end

    it "is hidden with a single member" do
      assign_counts(total_pets: 1, adoptable_pets: 1, staff_count: 1)
      stub_policy(staff_policy)

      render

      assert_select "h2", text: I18n.t("shelters.dashboard.show.team.title"), count: 0
    end
  end

  describe "localization" do
    it "renders dashboard strings in Spanish" do
      I18n.with_locale(:es) do
        assign_counts(total_pets: 0, total_requests_count: 0)
        stub_policy(staff_policy)

        render

        assert_select "h2", text: I18n.t("shelters.dashboard.show.empty_state.title", name: shelter.name, locale: :es)
        assert_select "a[href='#{new_shelter_pet_path}']", text: I18n.t("shelters.dashboard.show.empty_state.primary_cta", locale: :es)
      end
    end
  end
end
