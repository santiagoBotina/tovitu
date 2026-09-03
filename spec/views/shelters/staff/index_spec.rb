require "rails_helper"

RSpec.describe "shelters/staff/index", type: :view do
  let(:shelter) { create(:shelter) }
  let(:admin) { create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter) }

  before do
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:shelter, shelter)
    assign(:staff_members, [])
    assign(:pending_invitations, [])
    # Capture the local so the stub doesn't recurse into the view's own
    # current_user lookup.
    current_user = admin
    view.singleton_class.send(:define_method, :current_user) { current_user }
    # The admin (owner) manages the shelter, so the view's policy gate passes.
    policy_double = double(manage?: true)
    view.singleton_class.send(:define_method, :policy) { |_record| policy_double }
  end

  describe "standardized page header" do
    it "renders the title, subtitle, and back link to the shelter dashboard" do
      render

      assert_select "h1", text: I18n.t("shelters.staff.index.title")
      assert_select "p", text: I18n.t("shelters.staff.index.subtitle")
      assert_select "a[href='#{shelter_dashboard_path(shelter_id: shelter)}']", text: I18n.t("shared.back")
    end
  end

  describe "staff members" do
    let(:staff) { create(:user, :verified, :shelter_staff_member, :onboarding_completed, shelter: shelter) }

    before { assign(:staff_members, [ admin, staff ]) }

    it "renders each member with their name, email, and localized role badge" do
      render

      assert_select "p", text: staff.name
      assert_select "p", text: staff.email
      assert_select "span", text: I18n.t("shelters.staff.roles.staff_member")
    end

    it "renders the role badge for the owner member" do
      render

      assert_select "span", text: I18n.t("shelters.staff.roles.owner")
    end

    it "shows the remove action for non-self members with the confirmation prompt" do
      render

      assert_select "form[action='#{shelter_staff_path(shelter_id: shelter, id: staff)}']"
      assert_select "button[data-turbo-confirm='#{I18n.t("shelters.staff.index.remove_confirm", name: staff.name)}']"
    end

    it "hides the remove action for the current user's own row" do
      render

      assert_select "form[action='#{shelter_staff_path(shelter_id: shelter, id: admin)}']", count: 0
    end
  end

  describe "pending invitations" do
    let(:pending_invitation) do
      create(:invitation, shelter: shelter, email: "pending@example.com", created_at: 2.days.ago)
    end
    let(:expired_invitation) do
      create(:invitation, :expired, shelter: shelter, email: "expired@example.com", created_at: 5.days.ago)
    end

    before { assign(:pending_invitations, [ pending_invitation, expired_invitation ]) }

    it "renders each invitation email with its invited-ago time and role" do
      render

      assert_select "p", text: "pending@example.com"
      expected = I18n.t("shelters.staff.index.invited_ago",
                        time: view.time_ago_in_words(pending_invitation.created_at))
      role_label = I18n.t("shelters.staff.roles.staff_member")
      assert_select "p", text: "#{expected} · #{role_label}"
    end

    it "renders a pending status badge for active invitations" do
      render

      assert_select "span", text: I18n.t("shelters.staff.index.pending")
    end

    it "renders an expired status badge for expired invitations" do
      render

      assert_select "span", text: I18n.t("shelters.staff.index.expired")
    end
  end

  describe "invite staff action" do
    before { assign(:staff_members, [ admin ]) }

    it "renders the invite CTA, the single-email invite form, and a required role selector" do
      render

      assert_select "summary", text: /#{Regexp.escape(I18n.t("shelters.staff.index.invite_cta"))}/
      assert_select "form[action='#{shelter_staff_index_path(shelter_id: shelter)}']"
      assert_select "input[type='email'][name='email']"
      assert_select "select[name='role'][required='required']"
      assert_select "option[value='administrator']"
      assert_select "option[value='staff_member']"
      assert_select "option[value='owner']", count: 0
      assert_select "input[type='submit'][value='#{I18n.t("shelters.staff.index.send_invitation")}']"
    end
  end

  describe "empty states" do
    context "with no staff members" do
      before { assign(:staff_members, []) }

      it "renders the intentional empty state with copy and an invite CTA" do
        render

        assert_select "h3", text: I18n.t("shelters.staff.index.empty_staff_title")
        assert_select "p", text: I18n.t("shelters.staff.index.empty_staff_description")
        assert_select "summary", text: /#{Regexp.escape(I18n.t("shelters.staff.index.invite_cta"))}/
        assert_select "form[action='#{shelter_staff_index_path(shelter_id: shelter)}']"
      end
    end

    context "with no pending invitations" do
      it "renders a subtle no-pending-invitations line instead of a blank card" do
        render

        assert_select "h2", text: I18n.t("shelters.staff.index.pending_invitations")
        assert_select "p", text: I18n.t("shelters.staff.index.no_pending_invitations")
      end
    end
  end
end
