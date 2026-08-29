FactoryBot.define do
  factory :favorites_import do
    user
    status { "pending" }
    requested_ids { [ 1 ] }
    total_count { requested_ids.length }
    imported_count { 0 }
  end
end
