require "rails_helper"

RSpec.describe "Password Resets" do
  describe "GET /password_resets/new" do
    it "renders the forgot password form" do
      get new_password_reset_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Forgot your password")
    end
  end

  describe "POST /password_resets" do
    context "with a valid email" do
      let(:user) { create(:user, :verified) }

      it "sends a password reset email" do
        expect { post password_resets_path, params: { password_reset: { email: user.email } } }
          .to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end

      it "redirects to check email page" do
        post password_resets_path, params: { password_reset: { email: user.email } }
        expect(response).to redirect_to(check_email_password_resets_path)
      end

      it "creates a password reset token" do
        expect { post password_resets_path, params: { password_reset: { email: user.email } } }
          .to change(PasswordResetToken, :count).by(1)
      end
    end

    context "with a non-existent email" do
      it "redirects to check email page (fails silently)" do
        post password_resets_path, params: { password_reset: { email: "nonexistent@example.com" } }
        expect(response).to redirect_to(check_email_password_resets_path)
      end

      it "does not send an email" do
        expect { post password_resets_path, params: { password_reset: { email: "nonexistent@example.com" } } }
          .not_to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end
    end

    context "with an unverified user" do
      let(:user) { create(:user) }

      it "fails silently (does not reveal account status)" do
        post password_resets_path, params: { password_reset: { email: user.email } }
        expect(response).to redirect_to(check_email_password_resets_path)
      end

      it "does not send an email" do
        expect { post password_resets_path, params: { password_reset: { email: user.email } } }
          .not_to have_enqueued_mail(AuthenticationMailer, :password_reset)
      end
    end
  end

  describe "GET /password_resets/:id/edit" do
    context "with a valid token" do
      let(:user) { create(:user, :verified) }
      let!(:token) { create(:password_reset_token, user: user) }

      it "renders the reset form" do
        get edit_password_reset_path(id: token.token)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Reset your password")
      end
    end

    context "with an expired token" do
      let(:user) { create(:user, :verified) }
      let!(:token) { create(:password_reset_token, user: user, expires_at: 1.minute.ago) }

      it "redirects to the new password reset page" do
        travel_to 1.hour.from_now do
          get edit_password_reset_path(id: token.token)
          expect(response).to redirect_to(new_password_reset_path)
        end
      end
    end

    context "with an invalid token" do
      it "redirects to the new password reset page" do
        get edit_password_reset_path(id: "invalid-token")
        expect(response).to redirect_to(new_password_reset_path)
      end
    end
  end

  describe "PATCH /password_resets/:id" do
    context "with valid parameters" do
      let(:user) { create(:user, :verified) }
      let!(:token) { create(:password_reset_token, user: user) }

      it "updates the password" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(user.reload.authenticate("newpassword1")).to be_truthy
      end

      it "logs the user in" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(session[:user_id]).to eq(user.id)
      end

      it "consumes the token" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(token.reload).to be_consumed
      end

      it "redirects to root" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid parameters" do
      let(:user) { create(:user, :verified) }
      let!(:token) { create(:password_reset_token, user: user) }

      it "re-renders the form when password is too short" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "short", password_confirmation: "short" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the form when passwords don't match" do
        patch password_reset_path(id: token.token), params: {
          user: { password: "newpassword1", password_confirmation: "different" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
