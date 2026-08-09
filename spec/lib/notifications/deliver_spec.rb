require "rails_helper"

RSpec.describe Notifications::Deliver do
  include ActiveJob::TestHelper

  describe "#call" do
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let(:shelter) { create(:shelter) }
    let(:pet) { create(:pet, shelter: shelter) }
    let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }
    let(:actor) { create(:user, :verified) }

    let(:valid_attributes) do
      {
        recipient: adopter,
        kind: :request_submitted,
        notifiable: request,
        title: I18n.t("notifications.titles.request_submitted", pet_name: pet.name),
        body: I18n.t("notifications.bodies.request_submitted",
                      pet_name: pet.name,
                      shelter_name: shelter.name),
        actor: actor,
        action_url: "/adoption_requests/#{request.id}",
        metadata: { pet_name: pet.name }
      }
    end

    it "creates a notification record" do
      expect { described_class.call(**valid_attributes) }
        .to change(Notification, :count).by(1)
    end

    it "returns a successful result with the notification" do
      result = described_class.call(**valid_attributes)
      expect(result).to be_success
      expect(result.data).to be_a(Notification)
      expect(result.data).to be_persisted
    end

    it "assigns the correct attributes" do
      result = described_class.call(**valid_attributes)
      notification = result.data
      expect(notification.recipient).to eq(adopter)
      expect(notification.actor).to eq(actor)
      expect(notification.notifiable).to eq(request)
      expect(notification.kind).to eq("request_submitted")
      expect(notification.title).to eq(I18n.t("notifications.titles.request_submitted", pet_name: pet.name))
    end

    it "creates the notification as unread" do
      result = described_class.call(**valid_attributes)
      expect(result.data).not_to be_read
    end

    context "with invalid attributes" do
      it "returns failure when missing required fields" do
        result = described_class.call(
          recipient: nil,
          kind: :request_submitted,
          notifiable: request,
          title: "Test"
        )
        expect(result).to be_failure
      end
    end

    context "dedup guard (AC-7.1-4)" do
      it "does not create a duplicate record for the same (recipient, kind, notifiable)" do
        described_class.call(**valid_attributes)
        expect {
          described_class.call(**valid_attributes)
        }.not_to change(Notification, :count)
      end

      it "returns the existing record instead of double-delivering" do
        first = described_class.call(**valid_attributes).data
        second = described_class.call(**valid_attributes).data
        expect(second.id).to eq(first.id)
      end

      it "allows the same recipient to receive the same kind for a different notifiable" do
        other_pet = create(:pet, shelter: shelter)
        other_request = create(:adoption_request, pet: other_pet, adopter: adopter, shelter: shelter)
        described_class.call(**valid_attributes)
        expect {
          described_class.call(**valid_attributes.merge(notifiable: other_request))
        }.to change(Notification, :count).by(1)
      end

      it "allows different recipients to receive the same kind for the same notifiable" do
        staff = create(:user, :shelter_admin, shelter: shelter)
        described_class.call(**valid_attributes)
        expect {
          described_class.call(**valid_attributes.merge(recipient: staff))
        }.to change(Notification, :count).by(1)
      end
    end

    context "email delivery tracking (AC-7.1-8)" do
      it "does not mark delivery at enqueue — the tracker records the real outcome" do
        notification = described_class.call(**valid_attributes).data
        expect(notification.reload.email_delivered_at).to be_nil
        expect(notification.email_failed_at).to be_nil
      end

      it "records email_delivered_at once the mail is actually delivered" do
        notification = described_class.call(**valid_attributes).data
        perform_enqueued_jobs
        expect(notification.reload.email_delivered_at).not_to be_nil
        expect(notification.email_failed_at).to be_nil
      end

      it "does not mark anything when the channel is disabled" do
        create(:notification_preference, user: adopter, email: false)
        notification = described_class.call(**valid_attributes).data
        expect(notification.reload.email_delivered_at).to be_nil
        expect(notification.email_failed_at).to be_nil
      end

      it "records email_failed_at and the error message when enqueue raises" do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(StandardError, "boom")
        notification = described_class.call(**valid_attributes).data
        expect(notification.reload.email_failed_at).not_to be_nil
        expect(notification.email_error).to include("boom")
      end

      it "returns success even when the email fails (in-app delivery is unaffected)" do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(StandardError, "boom")
        result = described_class.call(**valid_attributes)
        expect(result).to be_success
      end
    end

    context "in-app preference (AC-7.1-5 follow-up)" do
      let!(:preference) { create(:notification_preference, user: adopter, in_app: false, email: true) }

      it "does not create a record when in-app is disabled for the kind" do
        expect { described_class.call(**valid_attributes) }
          .not_to change(Notification, :count)
      end

      it "returns success without a notification record" do
        result = described_class.call(**valid_attributes)
        expect(result).to be_success
        expect(result.data).to be_nil
      end

      it "still delivers email when the email channel is enabled" do
        expect { described_class.call(**valid_attributes) }
          .to have_enqueued_mail(AdoptionMailer, :request_confirmation)
      end

      it "does not deliver email when the email channel is also disabled" do
        preference.update!(email: false)
        expect { described_class.call(**valid_attributes) }
          .not_to have_enqueued_mail(AdoptionMailer)
      end

      it "creates the record for kinds where in-app is enabled" do
        preference.update!(in_app: true)
        expect { described_class.call(**valid_attributes) }
          .to change(Notification, :count).by(1)
      end
    end

    context "when recipient has notification preferences" do
      let!(:preference) { create(:notification_preference, user: adopter, email: true) }

      it "delivers email when preference allows it" do
        expect { described_class.call(**valid_attributes) }
          .to have_enqueued_mail(AdoptionMailer, :request_confirmation)
      end

      it "does not deliver email when preference disables it" do
        preference.update!(email: false)
        expect { described_class.call(**valid_attributes) }
          .not_to have_enqueued_mail(AdoptionMailer, :request_confirmation)
      end

      it "does not deliver email for deferred kinds without a mailer route" do
        expect {
          described_class.call(**valid_attributes.merge(kind: :message_received))
        }.not_to have_enqueued_mail(AdoptionMailer)
      end
    end

    context "when recipient has no notification preference" do
      it "creates default preferences and delivers email" do
        adopter.notification_preference&.destroy!
        adopter.reload
        expect { described_class.call(**valid_attributes) }
          .to have_enqueued_mail(AdoptionMailer, :request_confirmation)
      end
    end

    context "when notification is for a shelter staff member" do
      let(:staff) { create(:user, :verified, :shelter_admin, shelter: shelter) }

      it "delivers new_request_notification email" do
        staff_attrs = valid_attributes.merge(
          recipient: staff,
          body: I18n.t("notifications.bodies.request_submitted_to_shelter",
                        adopter_name: adopter.name,
                        pet_name: pet.name)
        )
        expect { described_class.call(**staff_attrs) }
          .to have_enqueued_mail(AdoptionMailer, :new_request_notification)
      end
    end

    context "with request_withdrawn kind" do
      it "delivers request_withdrawn email" do
        attrs = valid_attributes.merge(
          kind: :request_withdrawn,
          recipient: shelter.users.first || create(:user, :shelter_admin, shelter: shelter),
          body: I18n.t("notifications.bodies.request_withdrawn",
                        adopter_name: adopter.name,
                        pet_name: pet.name)
        )
        expect { described_class.call(**attrs) }
          .to have_enqueued_mail(AdoptionMailer, :request_withdrawn)
      end
    end

    context "with accepted/declined kinds" do
      it "delivers status_changed email" do
        attrs = valid_attributes.merge(kind: :request_accepted)
        expect { described_class.call(**attrs) }
          .to have_enqueued_mail(AdoptionMailer, :status_changed)
      end
    end

    context "with welcome kind" do
      it "delivers AuthenticationMailer#welcome" do
        attrs = valid_attributes.merge(kind: :welcome, notifiable: adopter)
        expect { described_class.call(**attrs) }
          .to have_enqueued_mail(AuthenticationMailer, :welcome)
      end

      it "enqueues in the recipient's locale" do
        adopter.update!(locale: "es")
        attrs = valid_attributes.merge(kind: :welcome, notifiable: adopter)
        described_class.call(**attrs)
        job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        expect(job["locale"]).to eq("es")
      end
    end
  end
end
