require "rails_helper"

# Enforces AC-3.1-5 from specs/29_section_explanations_plan.md:
# every section explanation (and its title) must be i18n'd in en and es.
RSpec.describe "Section explanations i18n parity" do
  SECTION_KEYS = {
    "Explorer"              => { title: "pets.index.title",              subtitle: "pets.index.subtitle" },
    "My Pets"               => { title: "my.pets.index.title",           subtitle: "my.pets.index.subtitle" },
    "My Adoption Requests"  => { title: "adoption_requests.index.title", subtitle: "adoption_requests.index.subtitle" },
    "Incoming Requests"     => { title: "my.adoption_requests.index.title", subtitle: "my.adoption_requests.index.subtitle" },
    "Profile / Settings"    => { title: "authentication.profiles.edit.title", subtitle: "authentication.profiles.edit.subtitle" },
    "Notifications"         => { title: "notifications.index.title",     subtitle: "notifications.index.subtitle" },
    "Shelter Dashboard"     => { title: "shelters.dashboard.show.title", subtitle: "shelters.dashboard.show.subtitle" },
    "Shelter Pets"          => { title: "shelter.pets.index.title",      subtitle: "shelter.pets.index.subtitle" },
    "Shelter Adoption Requests" => { title: "shelter.adoption_requests.index.title", subtitle: "shelter.adoption_requests.index.subtitle" }
  }.freeze

  SECTION_KEYS.each do |section, keys|
    describe section do
      keys.each do |label, key|
        it "provides #{label} in en and es without translation gaps" do
          en = I18n.t(key, locale: :en, default: nil)
          es = I18n.t(key, locale: :es, default: nil)

          expect(en).to be_present, "missing en translation for #{key}"
          expect(es).to be_present, "missing es translation for #{key}"
          expect(en).not_to include("translation missing")
          expect(es).not_to include("translation missing")
        end
      end

      it "keeps the explanation concise (<= 20 words)" do
        key = keys[:subtitle]
        en = I18n.t(key, locale: :en)
        es = I18n.t(key, locale: :es)

        expect(en.split.count).to be <= 20, "en copy for #{key} exceeds 20 words"
        expect(es.split.count).to be <= 20, "es copy for #{key} exceeds 20 words"
      end
    end
  end
end
