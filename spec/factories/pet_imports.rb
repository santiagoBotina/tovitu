FactoryBot.define do
  factory :pet_import do
    shelter
    user
    file_name { "pets.csv" }
    status { "pending" }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
      total_count { 1 }
      imported_count { 1 }
      summary { { "imported" => [ { "row" => 2, "name" => "Rex", "id" => 1 } ], "duplicates" => [], "errors" => [] } }
    end

    trait :failed do
      status { "failed" }
      completed_at { Time.current }
      error { "Oops" }
    end
  end
end
