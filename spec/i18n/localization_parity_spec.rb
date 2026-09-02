require "rails_helper"

# Enforces AC-33-15 from specs/33_localization_and_i18n_plan.md:
# every string used by the auth flow and the pet age badge exists in both
# en.yml and es.yml (en/es parity, no key drift).
RSpec.describe "Localization key parity" do
  AUTH_KEYS = %w[
    authentication.role_toggle.aria_label
    authentication.role_toggle.individual
    authentication.role_toggle.adopter
    authentication.role_toggle.shelter
    authentication.sessions.new.title
    authentication.sessions.new.subtitle
    authentication.sessions.new.individual_title
    authentication.sessions.new.adopter_title
    authentication.sessions.new.shelter_title
    authentication.sessions.new.email_label
    authentication.sessions.new.password_label
    authentication.sessions.new.forgot_password
    authentication.sessions.new.submit
    authentication.sessions.new.signup_prompt
    authentication.sessions.new.signup_link
    authentication.sessions.new_individual.title
    authentication.sessions.new_individual.subtitle
    authentication.sessions.new_individual.email_label
    authentication.sessions.new_individual.password_label
    authentication.sessions.new_individual.forgot_password
    authentication.sessions.new_individual.submit
    authentication.sessions.new_individual.signup_prompt
    authentication.sessions.new_individual.signup_link
    authentication.sessions.new_adopter.title
    authentication.sessions.new_adopter.subtitle
    authentication.sessions.new_adopter.email_label
    authentication.sessions.new_adopter.password_label
    authentication.sessions.new_adopter.forgot_password
    authentication.sessions.new_adopter.submit
    authentication.sessions.new_adopter.signup_prompt
    authentication.sessions.new_adopter.signup_link
    authentication.sessions.new_shelter.title
    authentication.sessions.new_shelter.subtitle
    authentication.sessions.new_shelter.email_label
    authentication.sessions.new_shelter.password_label
    authentication.sessions.new_shelter.forgot_password
    authentication.sessions.new_shelter.submit
    authentication.sessions.new_shelter.signup_prompt
    authentication.sessions.new_shelter.signup_link
    authentication.registrations.new.title_individual
    authentication.registrations.new.subtitle_individual
    authentication.registrations.new.title_shelter
    authentication.registrations.new.subtitle_shelter
    authentication.registrations.new.name_label
    authentication.registrations.new.email_label
    authentication.registrations.new.password_label
    authentication.registrations.new.password_hint
    authentication.registrations.new.confirm_label
    authentication.registrations.new.submit
    authentication.registrations.new.login_prompt
    authentication.registrations.new.login_link
    authentication.registrations.check_email.title
    authentication.registrations.check_email.body
    authentication.registrations.check_email.didnt_receive
    authentication.registrations.check_email.resend
    authentication.registrations.check_email.back
    authentication.passwords.new.title
    authentication.passwords.new.subtitle
    authentication.passwords.new.email_label
    authentication.passwords.new.submit
    authentication.passwords.new.login_prompt
    authentication.passwords.new.login_link
    authentication.passwords.check_email.title
    authentication.passwords.check_email.body
    authentication.passwords.check_email.back
    authentication.passwords.edit.title
    authentication.passwords.edit.subtitle
    authentication.passwords.edit.password_label
    authentication.passwords.edit.password_hint
    authentication.passwords.edit.confirm_label
    authentication.passwords.edit.submit
    authentication.verifications.expired.title
    authentication.verifications.expired.body
    authentication.verifications.expired.resend
    authentication.verifications.expired.back
    authentication.verifications.already_verified.title
    authentication.verifications.already_verified.body
    authentication.verifications.already_verified.login
    errors.authenticate_user.locked
    errors.authenticate_user.unverified
    errors.authenticate_user.invalid
    errors.authenticate_user.role_mismatch
    errors.verify_email.invalid
    errors.verify_email.expired
    errors.resend_verification.already_verified
    errors.reset_password.invalid
    errors.reset_password.expired
    errors.register_user.invalid_role
    flash.sessions.create.success
    flash.sessions.destroy.success
    flash.sessions.require_authentication
    flash.sessions.require_no_authentication
    flash.registrations.create.success
    flash.passwords.create.success
    flash.passwords.edit.expired
    flash.passwords.edit.already_expired
    flash.passwords.update.success
    flash.verifications.show.success
    activerecord.attributes.user.name
    activerecord.attributes.user.email
    activerecord.attributes.user.password
    activerecord.attributes.user.password_confirmation
    activerecord.attributes.user.role
  ].freeze

  AGE_KEYS = %w[
    pets.age_categories.baby
    pets.age_categories.young
    pets.age_categories.adult
    pets.age_categories.senior
    pets.age_display.one
    pets.age_display.other
    pets.show.life_preview_week_count.one
    pets.show.life_preview_week_count.other
  ].freeze

  # AC-36-17: every new REQ-10/REQ-11 string must exist in both locales.
  SPECIES_KEYS = Pet::SPECIES.map { |s| "pets.species.#{s}" }.freeze
  NL_SEARCH_KEYS = %w[
    pets.index.natural_language.label
    pets.index.natural_language.placeholder
    pets.index.natural_language.example
    pets.index.natural_language.submit
    pets.index.natural_language.loading
    pets.index.natural_language.understood_title
    pets.index.natural_language.search_title
    pets.index.natural_language.results_description
    pets.index.natural_language.reasons_title
    pets.index.natural_language.match_keyword
    pets.index.natural_language.empty_title
    pets.index.natural_language.empty_body
    pets.index.natural_language.browse_all
    pets.index.natural_language.invalid_title
    pets.index.natural_language.invalid_body
    pets.index.natural_language.clear
  ].freeze

  # AC-42-9: every new Adoption Policies show/edit string must exist in both locales.
  POLICIES_KEYS = %w[
    shelters.policies.show.title
    shelters.policies.show.description
    shelters.policies.show.edit_policies
    shelters.policies.show.not_set
    shelters.policies.show.no_fee
    shelters.policies.show.required
    shelters.policies.show.not_required
    shelters.policies.show.minimum_age
    shelters.policies.show.minimum_age_value
    shelters.policies.show.home_visit
    shelters.policies.show.fenced_yard
    shelters.policies.show.vet_reference
    shelters.policies.show.fee.amount
    shelters.policies.show.fee.description
    shelters.policies.show.groups.fee.title
    shelters.policies.show.groups.requirements.title
    shelters.policies.show.groups.other.title
    shelters.policies.show.empty.title
    shelters.policies.show.empty.description
    shelters.policies.edit.title
    shelters.policies.edit.subtitle
    shelters.policies.edit.groups.fee.title
    shelters.policies.edit.groups.requirements.title
    shelters.policies.edit.groups.other.title
    shelters.policies.edit.adoption_fee
    shelters.policies.edit.minimum_age
    shelters.policies.edit.fee_description
    shelters.policies.edit.fee_placeholder
    shelters.policies.edit.home_visit
    shelters.policies.edit.home_visit_desc
    shelters.policies.edit.fenced_yard
    shelters.policies.edit.fenced_yard_desc
    shelters.policies.edit.vet_reference
    shelters.policies.edit.vet_reference_desc
    shelters.policies.edit.other_requirements
    shelters.policies.edit.other_placeholder
    shelters.policies.edit.one_per_line
    shelters.policies.edit.submit
  ].freeze

  (AUTH_KEYS + AGE_KEYS + SPECIES_KEYS + NL_SEARCH_KEYS + POLICIES_KEYS).each do |key|
    it "provides #{key} in both en and es" do
      en = I18n.t(key, locale: :en, default: nil)
      es = I18n.t(key, locale: :es, default: nil)

      expect(en).to be_present, "missing en translation for #{key}"
      expect(es).to be_present, "missing es translation for #{key}"
      expect(en).not_to include("translation missing")
      expect(es).not_to include("translation missing")
    end
  end

  it "does not leak English age-unit strings into the Spanish age display" do
    es = I18n.t("pets.age_display", locale: :es, category: "Adulto", age: 5, count: 5)
    expect(es).to eq("Adulto (5 años)")
    expect(es).not_to include("years")
  end
end
