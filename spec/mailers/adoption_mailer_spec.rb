require "rails_helper"

RSpec.describe AdoptionMailer, type: :mailer do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed, locale: "en") }

  let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }

  def html_body(message)
    # Faker names can contain apostrophes (e.g. "D'Amore"), which ERB escapes
    # in the rendered HTML. Unescape before asserting on copy.
    raw = message.html_part ? message.html_part.body.to_s : message.body.to_s
    CGI.unescapeHTML(raw)
  end

  describe "#request_confirmation" do
    it "sends to the adopter" do
      mail = described_class.request_confirmation(request)
      expect(mail.to).to eq([ adopter.email ])
    end

    it "carries the X-Tovitu-Notification-Id header when routed with a notification id" do
      mail = described_class.request_confirmation(request, 42).deliver_now
      expect(mail.header["X-Tovitu-Notification-Id"].value).to eq("42")
    end

    it "omits the header when not routed through Deliver" do
      mail = described_class.request_confirmation(request).deliver_now
      expect(mail.header["X-Tovitu-Notification-Id"]).to be_nil
    end

    context "with a Spanish adopter" do
      before { adopter.update!(locale: "es") }

      it "renders content and URLs in Spanish" do
        mail = described_class.request_confirmation(request).deliver_now
        body = html_body(mail)
        expect(body).to include("Hola #{adopter.name}")
        expect(body).to include("/es/")
      end
    end

    context "with an English adopter" do
      it "renders content and URLs in English" do
        mail = described_class.request_confirmation(request).deliver_now
        body = html_body(mail)
        expect(body).to include("Hi #{adopter.name}")
        expect(body).to include("/en/")
      end
    end
  end

  describe "#status_changed" do
    it "sends to the adopter" do
      mail = described_class.status_changed(request)
      expect(mail.to).to eq([ adopter.email ])
    end

    it "renders in the adopter's locale" do
      adopter.update!(locale: "es")
      request.update!(status: :in_validation)
      mail = described_class.status_changed(request).deliver_now
      body = html_body(mail)
      expect(body).to include("está revisando tu solicitud")
      expect(body).to include("/es/")
    end

    it "renders decline reasons for declined requests (plan 32, problem 11)" do
      request.update!(status: :declined)
      request.record_timeline!(
        from_status: "pending",
        to_status: "declined",
        actor: adopter,
        metadata: { decline_reasons: [ "Not a fit", "Needs experience" ] }
      )
      mail = described_class.status_changed(request).deliver_now
      body = html_body(mail)
      expect(body).to include("Not a fit")
      expect(body).to include("Needs experience")
    end

    it "renders declined requests without reasons" do
      request.update!(status: :declined)
      mail = described_class.status_changed(request).deliver_now
      expect(html_body(mail)).to include("was not approved")
    end
  end

  describe "#new_request_notification" do
    let(:staff) { create(:user, :shelter_admin, shelter: shelter, locale: "es") }
    let(:english_adopter) { create(:user, :verified, :onboarding_completed, locale: "en") }
    let(:request) { create(:adoption_request, pet: pet, adopter: english_adopter, shelter: shelter) }

    it "sends to the recipient (shelter staff)" do
      mail = described_class.new_request_notification(request, staff)
      expect(mail.to).to eq([ staff.email ])
    end

    it "renders in the staff recipient's locale, never the adopter's (AC-7.1-6)" do
      mail = described_class.new_request_notification(request, staff).deliver_now
      body = html_body(mail)
      expect(body).to include("Hola #{staff.name}")
      expect(body).to include("/es/")
      expect(body).not_to include("/en/")
    end

    it "renders in the publisher's locale for individual publishers" do
      publisher = create(:user, :verified, :onboarding_completed, locale: "es")
      pet.update!(publisher: publisher, shelter: nil)
      request.update!(shelter: nil)
      mail = described_class.new_request_notification(request, publisher).deliver_now
      expect(html_body(mail)).to include("/es/")
    end
  end

  describe "#request_withdrawn" do
    let(:staff) { create(:user, :shelter_admin, shelter: shelter, locale: "es") }

    it "renders in the recipient's locale" do
      mail = described_class.request_withdrawn(request, staff).deliver_now
      body = html_body(mail)
      expect(body).to include("Hola #{staff.name}")
      expect(body).to include("/es/")
    end
  end
end
