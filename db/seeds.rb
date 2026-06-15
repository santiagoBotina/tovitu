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

puts "Seeded #{User.count} users and #{Shelter.count} shelters:"
puts "  admin@tovitu.com / password123  (admin, verified, Happy Paws Rescue)"
puts "  staff@tovitu.com / password123  (staff, verified, Happy Paws Rescue)"
puts "  furry.admin@example.com / password123  (admin, Furry Friends)"
puts "  critter.admin@example.com / password123  (admin, Critter Corner)"
puts "  unverified@tovitu.com / password123  (staff, unverified)"
