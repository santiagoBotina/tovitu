# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

return unless Rails.env.local?

shelter_admin = User.find_or_create_by!(email: "admin@tovitu.com") do |u|
  u.name = "Shelter Admin"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "admin"
  u.verified_at = Time.current
end

shelter_staff = User.find_or_create_by!(email: "staff@tovitu.com") do |u|
  u.name = "Shelter Staff"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "staff"
  u.verified_at = Time.current
end

unverified = User.find_or_create_by!(email: "unverified@tovitu.com") do |u|
  u.name = "Unverified User"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "staff"
end

happy_paws = Shelter.find_or_create_by!(name: "Happy Paws Rescue") do |s|
  s.street = "123 Main St"
  s.city = "Portland"
  s.state = "OR"
  s.zip = "97201"
  s.phone = "503-555-0123"
  s.website = "https://happypawsrescue.org"
  s.description = "Happy Paws Rescue is a nonprofit dedicated to finding loving homes for dogs and cats in the Pacific Northwest. We provide medical care, foster placement, and adoption counseling to ensure every pet finds the right family."
  s.species_served = [ "dog", "cat" ]
  s.hours = "Mon-Fri 10-6, Sat 10-4, Sun 12-4"
  s.status = "active"
  s.adoption_policies = {
    adoption_fee: 250,
    fee_description: "Covers vaccinations, spay/neuter, and microchipping",
    minimum_age: 21,
    home_visit_required: true,
    vet_reference_required: true
  }
  s.onboarding_completed = true
end

shelter_admin.update!(shelter: happy_paws, role: "admin") unless shelter_admin.shelter_id == happy_paws.id
shelter_staff.update!(shelter: happy_paws) unless shelter_staff.shelter_id == happy_paws.id

furry_friends = Shelter.find_or_create_by!(name: "Furry Friends Animal Shelter") do |s|
  s.street = "456 Oak Avenue"
  s.city = "Austin"
  s.state = "TX"
  s.zip = "78701"
  s.phone = "512-555-0456"
  s.website = "https://furryfriendsaustin.org"
  s.description = "Furry Friends has been serving the Austin community for over 20 years. We specialize in dog adoption and rehabilitation, helping hundreds of dogs find their forever homes each year."
  s.species_served = [ "dog" ]
  s.hours = "Tue-Sat 9-5"
  s.status = "active"
  s.adoption_policies = {
    adoption_fee: 175,
    fee_description: "Includes first set of vaccinations and a free vet checkup",
    minimum_age: 18,
    home_visit_required: false,
    fenced_yard_required: true,
    vet_reference_required: false
  }
  s.onboarding_completed = true
end

unless User.exists?(email: "furry.admin@example.com")
  furry_admin = User.create!(
    name: "Furry Admin",
    email: "furry.admin@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "admin",
    verified_at: Time.current,
    shelter: furry_friends
  )
end

critter_corner = Shelter.find_or_create_by!(name: "Critter Corner") do |s|
  s.street = "789 Pine Road"
  s.city = "Denver"
  s.state = "CO"
  s.zip = "80201"
  s.phone = "303-555-0789"
  s.description = "Critter Corner is a small, family-run shelter specializing in cats and small animals. We believe every critter deserves a second chance."
  s.species_served = [ "cat", "other" ]
  s.hours = "Mon-Sat 10-5"
  s.status = "active"
  s.adoption_policies = {
    adoption_fee: 100,
    fee_description: "Includes spay/neuter and initial vaccinations",
    minimum_age: 21,
    home_visit_required: true
  }
  s.onboarding_completed = true
end

unless User.exists?(email: "critter.admin@example.com")
  critter_admin = User.create!(
    name: "Critter Admin",
    email: "critter.admin@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "admin",
    verified_at: Time.current,
    shelter: critter_corner
  )
end

# ── Pets ──────────────────────────────────────────────────────────
# Photos are not seeded here. Attach them via the UI or console:
#   pet.photos.attach(io: File.open("path/to/photo.jpg"), filename: "photo.jpg")

pets_data = [
  # ── Happy Paws Rescue (Portland, OR) ──────────────────────────
  {
    shelter: happy_paws,
    name: "Luna",
    species: "dog",
    breed: "Labrador Retriever",
    age_category: "young",
    birth_date: Date.new(2024, 3, 15),
    size: "large",
    sex: "female",
    description: "Luna is a sweet, energetic Labrador who loves playing fetch and going on long walks. She's great with children and other dogs. Fully vaccinated and spayed.",
    personality_traits: [ "friendly", "energetic", "playful", "affectionate" ],
    medical_notes: "Fully vaccinated. No known medical issues.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: false,
    requirements: "Needs a home with a fenced yard. Active family preferred. Not suitable for homes with cats.",
    status: "available"
  },
  {
    shelter: happy_paws,
    name: "Simba",
    species: "cat",
    breed: "Domestic Short Hair",
    age_category: "adult",
    birth_date: Date.new(2021, 8, 10),
    size: "medium",
    sex: "male",
    description: "Simba is a regal gentleman who enjoys lounging in sunbeams and gentle lap time. He's independent but affectionate on his own terms. Litter box trained.",
    personality_traits: [ "independent", "cuddly", "calm", "gentle" ],
    medical_notes: "Had a mild urinary tract infection in 2024, resolved with treatment. Currently on a special diet.",
    spayed_neutered: true,
    vaccinated: true,
    special_needs: true,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: true,
    requirements: "Needs a quiet home without dogs. Special urinary diet required.",
    status: "available"
  },
  {
    shelter: happy_paws,
    name: "Buddy",
    species: "dog",
    breed: "Beagle Mix",
    age_category: "baby",
    birth_date: Date.new(2026, 1, 20),
    size: "small",
    sex: "male",
    description: "Buddy is a playful puppy with a curious nose and a wagging tail. He's working on potty training and basic commands. Full of love and energy!",
    personality_traits: [ "playful", "curious", "energetic", "friendly" ],
    medical_notes: "First round of vaccinations complete. Due for boosters in 2 weeks.",
    spayed_neutered: false,
    vaccinated: false,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Needs a family committed to training and socialization. Puppy-proof home required.",
    status: "available"
  },
  {
    shelter: happy_paws,
    name: "Mittens",
    species: "cat",
    breed: "Tuxedo",
    age_category: "senior",
    birth_date: Date.new(2016, 11, 3),
    size: "medium",
    sex: "female",
    description: "Mittens is a sweet senior lady looking for a quiet retirement home. She loves soft blankets, chin scratches, and watching birds from the window.",
    personality_traits: [ "calm", "gentle", "affectionate", "quiet" ],
    medical_notes: "Has early stage kidney disease, requires prescription diet. Regular vet checkups needed.",
    spayed_neutered: true,
    vaccinated: true,
    special_needs: true,
    good_with_children: false,
    good_with_dogs: false,
    good_with_cats: true,
    requirements: "Quiet home without young children or dogs. Senior adopter discount available.",
    status: "available"
  },
  {
    shelter: happy_paws,
    name: "Rocky",
    species: "dog",
    breed: "Pit Bull Terrier Mix",
    age_category: "adult",
    birth_date: Date.new(2020, 6, 12),
    size: "large",
    sex: "male",
    description: "Rocky is a loyal, muscular guy with a heart of gold. He's been through obedience training and knows all basic commands. A true companion.",
    personality_traits: [ "loyal", "gentle", "protective", "well-trained" ],
    medical_notes: "Fully vaccinated. Microchipped. No medical issues.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: false,
    requirements: "Experienced owner preferred. Must be only pet in the home. Strong fence required.",
    status: "on_hold"
  },

  # ── Furry Friends Animal Shelter (Austin, TX) ─────────────────
  {
    shelter: furry_friends,
    name: "Daisy",
    species: "dog",
    breed: "Golden Retriever",
    age_category: "adult",
    birth_date: Date.new(2020, 1, 8),
    size: "large",
    sex: "female",
    description: "Daisy is the quintessential family dog — friendly, patient, and endlessly loving. She's excellent with children and has completed advanced obedience training.",
    personality_traits: [ "friendly", "gentle", "patient", "intelligent" ],
    medical_notes: "Fully vaccinated, spayed, microchipped. All clear.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Active family preferred. Fenced yard ideal but not required with daily walks.",
    status: "available"
  },
  {
    shelter: furry_friends,
    name: "Zeus",
    species: "dog",
    breed: "German Shepherd",
    age_category: "young",
    birth_date: Date.new(2024, 5, 30),
    size: "large",
    sex: "male",
    description: "Zeus is a smart, energetic young shepherd who thrives on structure and activity. He's a fast learner and would excel in agility or working roles.",
    personality_traits: [ "intelligent", "energetic", "loyal", "confident" ],
    medical_notes: "Fully vaccinated. Neutered. Hip x-rays clear (OFA good).",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: false,
    requirements: "Experienced large-breed owner required. Needs daily vigorous exercise and mental stimulation. Fenced yard mandatory.",
    status: "available"
  },
  {
    shelter: furry_friends,
    name: "Coco",
    species: "dog",
    breed: "Cocker Spaniel",
    age_category: "senior",
    birth_date: Date.new(2015, 9, 14),
    size: "medium",
    sex: "female",
    description: "Coco is a gentle senior who still has plenty of love to give. She enjoys short walks, belly rubs, and napping on the couch next to her person.",
    personality_traits: [ "gentle", "affectionate", "calm", "sweet" ],
    medical_notes: "Has arthritis managed with supplements. Needs joint-support diet. Some hearing loss.",
    spayed_neutered: true,
    vaccinated: true,
    special_needs: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Single-story home preferred (stairs are difficult). Soft bedding areas needed.",
    status: "available"
  },
  {
    shelter: furry_friends,
    name: "Bear",
    species: "dog",
    breed: "Siberian Husky",
    age_category: "young",
    birth_date: Date.new(2023, 12, 1),
    size: "large",
    sex: "male",
    description: "Bear is a stunning husky with striking blue eyes and a mischievous spirit. He's an escape artist with endless energy — but incredibly affectionate.",
    personality_traits: [ "energetic", "independent", "playful", "vocal" ],
    medical_notes: "Vaccinations current. Neutered. Microchipped. No known issues.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: false,
    requirements: "Secure, tall fencing required (Husky can jump!). Not for apartments. Needs cold climate considerations.",
    status: "available"
  },
  {
    shelter: furry_friends,
    name: "Molly",
    species: "dog",
    breed: "Dachshund Mix",
    age_category: "baby",
    birth_date: Date.new(2026, 3, 10),
    size: "small",
    sex: "female",
    description: "Molly is a tiny sweetheart with a big personality. She's the last of her litter and ready to find her forever family. Loves cuddles and squeaky toys.",
    personality_traits: [ "playful", "curious", "cuddly", "brave" ],
    medical_notes: "First vaccinations given. Too young for spay yet — appointment scheduled.",
    spayed_neutered: false,
    vaccinated: false,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Puppy-proof home. Adopter must continue vaccination schedule and complete spay at 6 months.",
    status: "available"
  },
  {
    shelter: furry_friends,
    name: "Shadow",
    species: "dog",
    breed: "Mixed Breed",
    age_category: "adult",
    birth_date: Date.new(2022, 4, 22),
    size: "medium",
    sex: "male",
    description: "Shadow is a sweet, somewhat shy dog who warms up beautifully with patience. He was found as a stray and is learning to trust humans again.",
    personality_traits: [ "shy", "gentle", "loyal", "sensitive" ],
    medical_notes: "Vaccinated, neutered, microchipped. Had heartworm treatment in 2024 — now fully recovered.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: false,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Patient, quiet household. Adults-only recommended. Another calm dog in home would help his confidence.",
    status: "available"
  },

  # ── Critter Corner (Denver, CO) ───────────────────────────────
  {
    shelter: critter_corner,
    name: "Whiskers",
    species: "cat",
    breed: "Maine Coon Mix",
    age_category: "adult",
    birth_date: Date.new(2021, 2, 28),
    size: "large",
    sex: "male",
    description: "Whiskers is a magnificent floof with a gentle disposition. He's great with children and other cats, and has the most soothing purr you'll ever hear.",
    personality_traits: [ "gentle", "cuddly", "friendly", "vocal" ],
    medical_notes: "Fully vaccinated. Neutered. Healthy weight. Regular grooming needed for his long coat.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: true,
    requirements: "Regular brushing required. Indoor-only home. Cat trees recommended.",
    status: "available"
  },
  {
    shelter: critter_corner,
    name: "Lily",
    species: "cat",
    breed: "Calico",
    age_category: "young",
    birth_date: Date.new(2024, 7, 15),
    size: "small",
    sex: "female",
    description: "Lily is a playful kitten with a beautiful calico coat. She's full of energy, loves wand toys, and will keep you entertained for hours.",
    personality_traits: [ "playful", "energetic", "curious", "affectionate" ],
    medical_notes: "Vaccinations current. Spay appointment scheduled. Healthy and active.",
    spayed_neutered: false,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Active household. Another young cat or dog playmate preferred.",
    status: "available"
  },
  {
    shelter: critter_corner,
    name: "Oscar",
    species: "cat",
    breed: "Orange Tabby",
    age_category: "senior",
    birth_date: Date.new(2017, 5, 8),
    size: "medium",
    sex: "male",
    description: "Oscar is a laid-back orange tabby who just wants a warm lap and regular meal times. He gets along with everyone and is the easiest cat you'll ever meet.",
    personality_traits: [ "calm", "friendly", "easygoing", "affectionate" ],
    medical_notes: "Senior wellness check done. Slight dental tartar. On joint supplement.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: true,
    good_with_cats: true,
    requirements: "Indoor-only. Regular vet checkups. Soft bedding for senior joints.",
    status: "available"
  },
  {
    shelter: critter_corner,
    name: "Pepper",
    species: "other",
    breed: "Holland Lop Rabbit",
    age_category: "baby",
    birth_date: Date.new(2025, 8, 1),
    size: "small",
    sex: "female",
    description: "Pepper is a friendly, litter-box trained rabbit who loves exploring and being petted. She does little happy jumps (binkies) when she's excited!",
    personality_traits: [ "friendly", "playful", "curious", "gentle" ],
    medical_notes: "Spayed. Vaccinated for RHDV2. Nail trim included.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: true,
    requirements: "Needs a spacious enclosure or rabbit-proofed room. Fresh hay and veggies daily.",
    status: "available"
  },
  {
    shelter: critter_corner,
    name: "Salem",
    species: "cat",
    breed: "Black Domestic Short Hair",
    age_category: "adult",
    birth_date: Date.new(2020, 10, 31),
    size: "medium",
    sex: "male",
    description: "Salem is a sleek black cat with a charming personality. He's a bit shy at first but becomes a velcro cat once he trusts you. Loves window perches and laser pointers.",
    personality_traits: [ "shy", "affectionate", "playful", "loyal" ],
    medical_notes: "Fully vaccinated. Neutered. Healthy. No special needs.",
    spayed_neutered: true,
    vaccinated: true,
    good_with_children: false,
    good_with_dogs: false,
    good_with_cats: true,
    requirements: "Quiet, patient home. Indoor-only. Adults or older children recommended.",
    status: "available"
  },
  {
    shelter: critter_corner,
    name: "Pancake",
    species: "other",
    breed: "Guinea Pig",
    age_category: "baby",
    birth_date: Date.new(2026, 4, 5),
    size: "small",
    sex: "female",
    description: "Pancake is a tiny, squeaky guinea pig who will melt your heart. She loves fresh veggies, tunnels, and being gently held.",
    personality_traits: [ "gentle", "curious", "vocal", "friendly" ],
    medical_notes: "Healthy. No vaccinations needed. Nail trim included with adoption.",
    spayed_neutered: false,
    vaccinated: false,
    good_with_children: true,
    good_with_dogs: false,
    good_with_cats: false,
    requirements: "Needs at least one guinea pig companion (pairs adopted together or buddy available). Spacious cage with bedding.",
    status: "available"
  }
]

pets_data.each do |attrs|
  shelter = attrs.delete(:shelter)
  Pet.find_or_create_by!(shelter: shelter, name: attrs[:name]) do |pet|
    pet.assign_attributes(attrs)
  end
end

puts "Seeded #{User.count} users, #{Shelter.count} shelters, and #{Pet.count} pets:"
puts "  admin@tovitu.com / password123  (admin, verified, Happy Paws Rescue)"
puts "  staff@tovitu.com / password123  (staff, verified, Happy Paws Rescue)"
puts "  furry.admin@example.com / password123  (admin, Furry Friends)"
puts "  critter.admin@example.com / password123  (admin, Critter Corner)"
puts "  unverified@tovitu.com / password123  (staff, unverified)"
puts ""
puts "Pets:"
Pet.includes(:shelter).each do |pet|
  puts "  #{pet.name} (#{pet.species}) — #{pet.shelter.name} [#{pet.status}]"
end
