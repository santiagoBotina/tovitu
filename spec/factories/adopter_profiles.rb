FactoryBot.define do
  # Legacy alias used by older specs; "adopter" is a deprecated name for
  # "individual". Both factories write to the shared individual_profiles table.
  factory :adopter_profile do
    user
  end

  factory :individual_profile, class: "IndividualProfile" do
    user
  end
end
