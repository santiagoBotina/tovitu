require "rails_helper"

RSpec.describe "Notifications delivery lifecycle" do
  include ActiveJob::TestHelper

  it "tracks welcome + request emails end to end" do
    # Registration (no welcome yet)
    reg = Authentication::RegisterUser.call(
      name: "Ada", email: "ada#{SecureRandom.hex(4)}@example.com", password: "password123",
      password_confirmation: "password123", role: "individual", locale: "es"
    )
    expect(reg).to be_success
    user = User.find(reg.data[:id])
    expect(user.notifications.welcome.count).to eq(0)

    # Verification → welcome notification + welcome email
    token = user.email_verification_tokens.last
    Authentication::VerifyEmail.call(token: token.token)
    welcome = user.reload.notifications.welcome.first
    expect(welcome).to be_present
    expect(welcome.email_delivered_at).to be_nil

    # Run the welcome mail job → delivery tracker marks the record
    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
    expect(welcome.reload.email_delivered_at).not_to be_nil
    expect(welcome.email_failed_at).to be_nil

    # Submission → adopter request_confirmation + shelter staff notification
    user.update!(onboarding_completed_at: Time.current)
    shelter = create(:shelter)
    staff = create(:user, :verified, :shelter_admin, shelter: shelter)
    pet = create(:pet, shelter: shelter)
    result = Adoptions::SubmitRequest.call(adopter: user, pet: pet)
    expect(result).to be_success

    adopter_notif = user.notifications.request_submitted.find_by(notifiable: result.data)
    staff_notif = staff.notifications.request_submitted.find_by(notifiable: result.data)
    expect(adopter_notif).to be_present
    expect(staff_notif).to be_present
    expect(adopter_notif.email_delivered_at).to be_nil

    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
    expect(adopter_notif.reload.email_delivered_at).not_to be_nil
    expect(staff_notif.reload.email_delivered_at).not_to be_nil

    # Process accepted → status_changed email
    ProcessResult = Adoptions::ProcessRequest.call(
      request: result.data, new_status: "accepted", actor: staff
    )
    expect(ProcessResult).to be_success
    accepted_notif = user.notifications.request_accepted.find_by(notifiable: result.data)
    expect(accepted_notif).to be_present
    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
    expect(accepted_notif.reload.email_delivered_at).not_to be_nil

    # A user with in_app disabled gets the email but no record
    user.notification_preference.update!(in_app: false)
    other_pet = create(:pet, shelter: shelter)
    other = Adoptions::SubmitRequest.call(adopter: user, pet: other_pet)
    expect(other).to be_success
    expect(user.notifications.request_submitted.where(notifiable: other.data).count).to eq(0)
  end
end
