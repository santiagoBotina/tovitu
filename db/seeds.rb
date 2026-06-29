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

adopter = User.find_or_create_by!(email: "adopter@tovitu.com") do |u|
  u.name = "Alex Adopter"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "adopter"
  u.verified_at = Time.current
  u.onboarding_completed_at = Time.current
end

unless AdopterProfile.exists?(user: adopter)
  AdopterProfile.create!(
    user: adopter,
    activity_level: "active",
    ideal_companion: "playful_companion",
    pet_experience: "years_of_experience",
    daily_time_available: "2_to_4h",
    personality: "friendly_social",
    adoption_priority: "Looking for an active dog to join me on hikes and runs."
  )
end

# ── Image helpers ──────────────────────────────────────────────────
def fetch_image(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
    req = Net::HTTP::Get.new(uri)
    http.request(req)
  end
  return nil unless response.is_a?(Net::HTTPOK)

  ext = File.extname(URI.parse(url).path).presence || ".png"
  filename = "seed#{ext}"
  { io: StringIO.new(response.body), filename: filename }
rescue StandardError => e
  Rails.logger.warn "  ! Failed to download #{url}: #{e.message}"
  nil
end

def generate_svg_logo(text, bg_color:)
  svg = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
      <rect width="400" height="400" fill="#{bg_color}"/>
      <text x="200" y="200" dominant-baseline="central" text-anchor="middle"
            fill="white" font-family="system-ui,sans-serif" font-size="120" font-weight="bold">#{text}</text>
    </svg>
  SVG
  { io: StringIO.new(svg), filename: "logo.svg" }
end

def generate_svg_pet_photo(text, bg_color: "#6366f1")
  svg = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
      <rect width="800" height="600" fill="#{bg_color}" opacity="0.15"/>
      <circle cx="400" cy="250" r="100" fill="#{bg_color}" opacity="0.3"/>
      <path d="M200 450 Q400 300 600 450" fill="none" stroke="#{bg_color}" stroke-width="4" opacity="0.3"/>
      <text x="400" y="500" dominant-baseline="central" text-anchor="middle"
            fill="#{bg_color}" font-family="system-ui,sans-serif" font-size="36" font-weight="bold">#{text}</text>
    </svg>
  SVG
  { io: StringIO.new(svg), filename: "pet.svg" }
end

def attach_with_key!(record, attachment_name, image, key)
  return unless image

  image[:io].rewind
  content_type = Marcel::MimeType.for(image[:io])
  image[:io].rewind

  blob = ActiveStorage::Blob.create_and_upload!(
    io: image[:io],
    filename: image[:filename],
    content_type: content_type,
    key: key
  )
  record.send(attachment_name).attach(blob)
end

# ── Attach shelter logos ─────────────────────────────────────────
shelter_logos = {
  happy_paws => { url: "https://placehold.co/400x400/3b82f6/ffffff.png?text=HPR", bg: "#3b82f6", text: "HPR" },
  furry_friends => { url: "https://placehold.co/400x400/10b981/ffffff.png?text=FF", bg: "#10b981", text: "FF" }
}

shelter_logos.each do |shelter, opts|
  next if shelter.logo.attached?

  image = fetch_image(opts[:url]) || generate_svg_logo(opts[:text], bg_color: opts[:bg])
  key = StorageKeyGenerator.shelter_logo(shelter.name)
  attach_with_key!(shelter, :logo, image, key)
  puts "  Attached logo to #{shelter.name}"
end

# ── Pets ──────────────────────────────────────────────────────────
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

]

pets_data.each do |attrs|
  shelter = attrs.delete(:shelter)
  Pet.find_or_create_by!(shelter: shelter, name: attrs[:name]) do |pet|
    pet.assign_attributes(attrs)
  end
end

# ── Attach pet photos ────────────────────────────────────────────
pet_image_urls = {
  %w[Luna]   => [ "https://placehold.co/800x600/6366f1/ffffff.png?text=Luna+1", "https://placehold.co/800x600/4f46e5/ffffff.png?text=Luna+2" ],
  %w[Simba]  => [ "https://placehold.co/800x600/f97316/ffffff.png?text=Simba+1", "https://placehold.co/800x600/ea580c/ffffff.png?text=Simba+2" ],
  %w[Buddy]  => [ "https://placehold.co/600x600/8b5cf6/ffffff.png?text=Buddy+1", "https://placehold.co/600x600/7c3aed/ffffff.png?text=Buddy+2" ],
  %w[Mittens] => [ "https://placehold.co/800x600/ec4899/ffffff.png?text=Mittens" ],
  %w[Rocky]  => [ "https://placehold.co/800x800/6b7280/ffffff.png?text=Rocky" ],
  %w[Daisy]  => [ "https://placehold.co/800x600/10b981/ffffff.png?text=Daisy+1", "https://placehold.co/800x600/059669/ffffff.png?text=Daisy+2" ],
  %w[Zeus]   => [ "https://placehold.co/800x800/3b82f6/ffffff.png?text=Zeus" ],
  %w[Coco]   => [ "https://placehold.co/600x600/d97706/ffffff.png?text=Coco" ],
  %w[Bear]   => [ "https://placehold.co/800x600/1f2937/ffffff.png?text=Bear+1", "https://placehold.co/800x600/374151/ffffff.png?text=Bear+2" ],
  %w[Molly]  => [ "https://placehold.co/600x600/f472b6/ffffff.png?text=Molly" ],
  %w[Shadow] => [ "https://placehold.co/800x600/78716c/ffffff.png?text=Shadow" ]
}

Pet.find_each do |pet|
  next if pet.photos.attached?
  name_key = pet_image_urls.keys.find { |names| names.include?(pet.name) }
  next unless name_key

  url_list = pet_image_urls[name_key]
  url_list.each do |url|
    image = fetch_image(url)
    image ||= generate_svg_pet_photo(pet.name)
    key = StorageKeyGenerator.pet_photo(pet.shelter.name, pet.name)
    attach_with_key!(pet, :photos, image, key)
  end

  if pet.photos.attached?
    pet.update_column(:photo_order, pet.photos.map(&:blob_id))
    puts "  Attached #{pet.photos.count} photo(s) to #{pet.name}"
  end
end

# ── Adoptions ───────────────────────────────────────────────────
return unless defined?(AdoptionApplication)

happy_paws_pets = Pet.where(shelter: happy_paws)
furry_pets = Pet.where(shelter: furry_friends)

# Helper to create applications
seed_app = ->(pet:, name:, email:, status:, phone: nil, housing: nil, answers: {}, token: nil, extra: {}) {
  token ||= Adoptions::TokenGenerator.generate
  app = AdoptionApplication.find_or_create_by!(pet: pet, applicant_email: email) do |a|
    a.shelter_id = pet.shelter_id
    a.applicant_name = name
    a.applicant_phone = phone || "555-0100"
    a.applicant_address = "123 Main St, #{pet.shelter.city}, #{pet.shelter.state}"
    a.housing_type = housing || "house"
    a.current_pets = "I have a friendly dog at home."
    a.pet_experience = "I've had pets for over 10 years."
    a.questionnaire_answers = answers
    a.token = token
    a.status = status
    extra.each { |k, v| a.send(:"#{k}=", v) }
  end
  unless app.adoption_timeline_events.exists?(event_type: "created")
    app.adoption_timeline_events.create!(
      event_type: "created",
      metadata: { applicant_email: email, pet_id: pet.id, pet_name: pet.name }
    )
  end
  app
}

luna = happy_paws_pets.find_by!(name: "Luna")
buddy = happy_paws_pets.find_by!(name: "Buddy")
simba = happy_paws_pets.find_by!(name: "Simba")
daisy = furry_pets.find_by!(name: "Daisy")
zeus = furry_pets.find_by!(name: "Zeus")

# Pending application for Luna
app1 = seed_app.call(
  pet: luna, name: "Alice Johnson", email: "alice@example.com",
  status: "pending", housing: "house",
  answers: { interest_reason: "I love labs!", living_environment: "both",
             hours_alone: "4", previous_pets: "Yes, grew up with dogs",
             household_agreement: true, landlord_permission: true }
)

# Under review application for Buddy
app2 = seed_app.call(
  pet: buddy, name: "Bob Smith", email: "bob@example.com",
  status: "under_review", housing: "house",
  answers: { interest_reason: "Looking for a family dog",
             living_environment: "both", hours_alone: "2",
             previous_pets: "Had a beagle for 12 years",
             household_agreement: true, landlord_permission: true }
)
unless app2.adoption_timeline_events.exists?(event_type: "info_received")
  app2.adoption_timeline_events.create!(
    event_type: "info_received",
    metadata: { reviewed_by: shelter_staff.name }
  )
end

# Approved application for Simba (on hold)
app3 = seed_app.call(
  pet: simba, name: "Carol Davis", email: "carol@example.com",
  status: "approved", housing: "apartment",
  answers: { interest_reason: "I love cats and have experience with special needs",
             living_environment: "indoor", hours_alone: "6",
             previous_pets: "Had a senior cat before",
             veterinarian: "Dr. Smith at City Vet",
             household_agreement: true, landlord_permission: true }
)
unless app3.adoption_timeline_events.exists?(event_type: "approved")
  app3.update!(hold_expires_at: 48.hours.from_now)
  app3.adoption_timeline_events.create!(
    event_type: "approved",
    metadata: { reviewed_by: shelter_staff.name, hold_expires_at: app3.hold_expires_at }
  )
end

# Rejected application for Daisy
app4 = seed_app.call(
  pet: daisy, name: "David Wilson", email: "david@example.com",
  status: "rejected", housing: "apartment",
  answers: { interest_reason: "Want a guard dog", living_environment: "outdoor",
             hours_alone: "10", previous_pets: "None",
             household_agreement: false },
  extra: { rejection_reason: "unsuitable_home_environment" }
)
unless app4.adoption_timeline_events.exists?(event_type: "rejected")
  app4.adoption_timeline_events.create!(
    event_type: "rejected",
    metadata: { reviewed_by: "furry.admin@example.com", reason: "unsuitable_home_environment" }
  )
end

# Awaiting response for Zeus
app5 = seed_app.call(
  pet: zeus, name: "Eve Martinez", email: "eve@example.com",
  status: "awaiting_response", housing: "house",
  answers: { interest_reason: "I want an active companion",
             living_environment: "both", hours_alone: "3",
             previous_pets: "Had German Shepherds before",
             household_agreement: true, landlord_permission: true }
)
unless app5.adoption_timeline_events.exists?(event_type: "info_requested")
  app5.adoption_timeline_events.create!(
    event_type: "info_requested",
    metadata: { reviewed_by: "furry.admin@example.com",
                questions: [ "Do you have a fenced yard?", "Can you provide vet references?" ] }
  )
end

# A note on the under-review application
unless app2.adoption_notes.exists?
  app2.adoption_notes.create!(
    user: shelter_staff,
    content: "Spoke with Bob on the phone — seems like a great fit. Schedule meet-and-greet.",
    pinned: true
  )
end

puts ""
puts "Seeded #{AdoptionApplication.count} adoption applications:"
AdoptionApplication.includes(pet: :shelter).each do |app|
  puts "  #{app.applicant_name} → #{app.pet.name} (#{app.pet.shelter.name}) [#{app.status}]"
end

puts ""
puts "Seeded #{User.count} users, #{Shelter.count} shelters, and #{Pet.count} pets:"
puts "  admin@tovitu.com / password123  (admin, shelter, Happy Paws Rescue)"
puts "  staff@tovitu.com / password123  (staff, shelter, Happy Paws Rescue)"
puts "  furry.admin@example.com / password123  (admin, Furry Friends)"
puts "  adopter@tovitu.com / password123  (adopter, verified, onboarding completed)"
puts ""
puts "Pets:"
Pet.includes(:shelter).each do |pet|
  puts "  #{pet.name} (#{pet.species}) — #{pet.shelter.name} [#{pet.status}]"
end
