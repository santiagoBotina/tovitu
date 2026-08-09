require "rails_helper"

RSpec.describe AuthenticationMailer, type: :mailer do
  def html_body(message)
    CGI.unescapeHTML(message.html_part.body.to_s)
  end

  describe "#welcome" do
    let(:user) { create(:user, locale: "es") }

    it "sends to the user" do
      mail = described_class.welcome(user)
      expect(mail.to).to eq([ user.email ])
    end

    it "has the welcome subject" do
      mail = described_class.welcome(user)
      expect(mail.subject).to eq("¡Bienvenido a Tovitu!")
    end

    it "renders in the user's locale with locale-scoped URLs" do
      mail = described_class.welcome(user).deliver_now
      html = html_body(mail)
      expect(html).to include("¡Bienvenido a Tovitu, #{user.name}!")
      expect(html).to include("/es/")
    end

    it "falls back to English when the user has no locale" do
      user.update!(locale: nil)
      mail = described_class.welcome(user).deliver_now
      html = html_body(mail)
      expect(html).to include("Welcome to Tovitu, #{user.name}!")
      expect(html).to include("/en/")
    end

    it "carries the X-Tovitu-Notification-Id header when routed with a notification id" do
      mail = described_class.welcome(user, 7).deliver_now
      expect(mail.header["X-Tovitu-Notification-Id"].value).to eq("7")
    end
  end

  describe "#verification" do
    let(:user) { create(:user, locale: "es") }
    let(:token) { create(:email_verification_token, user: user) }

    it "builds a locale-scoped verification URL" do
      mail = described_class.verification(user, token).deliver_now
      html = html_body(mail)
      expect(html).to include("/es/verification")
    end
  end
end
