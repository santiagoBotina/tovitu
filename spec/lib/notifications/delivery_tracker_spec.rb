require "rails_helper"

RSpec.describe Notifications::DeliveryTracker do
  include ActiveJob::TestHelper

  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }
  let(:notification) do
    create(:notification,
      recipient: adopter,
      kind: "request_submitted",
      notifiable: request)
  end

  # Build a `deliver.action_mailer`-shaped payload: the encoded mail carries the
  # X-Tovitu-Notification-Id header, exactly as the routed mailers emit it.
  # The mail is processed but NOT delivered, so the real subscription can't
  # interfere with the fabricated-event assertions.
  def routed_mail
    AdoptionMailer.request_confirmation(request, notification.id).message
  end

  def tracker_args(mail, exception: nil)
    payload = { mail: mail.encoded, mailer: "AdoptionMailer", subject: mail.subject, to: mail.to }
    payload[:exception] = exception if exception
    now = Time.current
    [ "deliver.action_mailer", now, now, SecureRandom.hex(16), payload ]
  end

  describe "#call" do
    it "marks email_delivered_at for a successfully delivered routed mail" do
      described_class.call(*tracker_args(routed_mail))
      expect(notification.reload.email_delivered_at).not_to be_nil
      expect(notification.email_failed_at).to be_nil
    end

    it "records email_failed_at and the error when the payload carries an exception" do
      described_class.call(*tracker_args(routed_mail, exception: [ "StandardError", "smtp boom" ]))
      expect(notification.reload.email_failed_at).not_to be_nil
      expect(notification.email_error).to include("smtp boom")
      expect(notification.email_delivered_at).to be_nil
    end

    it "is a no-op for mails without the notification header" do
      mail = AdoptionMailer.request_confirmation(request).message
      expect {
        described_class.call(*tracker_args(mail))
      }.not_to change { notification.reload.email_delivered_at }
    end

    it "is a no-op when the notification no longer exists" do
      mail = routed_mail
      notification.destroy!
      expect {
        described_class.call(*tracker_args(mail))
      }.not_to raise_error
    end

    it "round-trips through the real subscription when the mail job runs" do
      result = Notifications::Deliver.call(
        recipient: adopter,
        kind: :request_submitted,
        notifiable: request,
        title: "Title",
        body: "Body",
        actor: nil,
        action_url: "/x",
        metadata: {}
      )
      expect(result.data.reload.email_delivered_at).to be_nil
      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
      expect(result.data.reload.email_delivered_at).not_to be_nil
    end
  end
end
