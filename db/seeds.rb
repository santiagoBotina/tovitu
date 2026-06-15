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

puts "Seeded #{User.count} users:"
puts "  admin@tovitu.com / password123  (admin, verified)"
puts "  staff@tovitu.com / password123  (staff, verified)"
puts "  unverified@tovitu.com / password123  (staff, unverified)"
