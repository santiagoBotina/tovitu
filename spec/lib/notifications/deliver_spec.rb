require "rails_helper"

RSpec.describe Notifications::Deliver do
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

      it "does not deliver email for kinds without a mailer mapping" do
        expect {
          described_class.call(**valid_attributes.merge(kind: :welcome))
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
  end
end
