require "rails_helper"

RSpec.describe "Email Verifications" do
  describe "GET /verification" do
    context "with a valid token" do
      let(:user) { create(:user, :onboarding_completed) }
      let!(:token) { create(:email_verification_token, user: user) }

      it "verifies the user" do
        expect { get verification_path(token: token.token) }
          .to change { user.reload.verified? }.from(false).to(true)
      end

      it "logs the user in" do
        get verification_path(token: token.token)
        expect(session[:user_id]).to eq(user.id)
      end

      it "consumes the token" do
        get verification_path(token: token.token)
        expect(token.reload).to be_consumed
      end

      it "redirects to root" do
        get verification_path(token: token.token)
        expect(response).to redirect_to(pets_path)
      end
    end

    context "with an expired token" do
      let(:user) { create(:user) }
      let!(:token) { create(:email_verification_token, user: user, expires_at: 1.minute.ago) }

      it "renders the expired page" do
        get verification_path(token: token.token)
        expect(response.body).to include("Link expired")
      end

      it "does not verify the user" do
        expect { get verification_path(token: token.token) }
          .not_to change { user.reload.verified? }
      end
    end

    context "with an already consumed token" do
      let(:user) { create(:user, :verified) }
      let!(:token) { create(:email_verification_token, user: user, consumed_at: Time.current) }

      it "renders the already verified page" do
        get verification_path(token: token.token)
        expect(response.body).to include("Already verified")
      end
    end

    context "with an invalid token" do
      it "redirects to root" do
        get verification_path(token: "invalid-token")
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
