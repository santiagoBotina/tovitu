# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_15_150851) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "email_verification_tokens", force: :cascade do |t|
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_email_verification_tokens_on_token"
    t.index ["user_id"], name: "index_email_verification_tokens_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "shelter_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invitations_on_created_by_id"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["shelter_id"], name: "index_invitations_on_shelter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "login_attempts", force: :cascade do |t|
    t.datetime "attempted_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "ip_address", null: false
    t.boolean "success", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["email", "attempted_at"], name: "index_login_attempts_on_email_and_attempted_at"
    t.index ["email"], name: "index_login_attempts_on_email"
  end

  create_table "password_reset_tokens", force: :cascade do |t|
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_password_reset_tokens_on_token"
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
  end

  create_table "pets", force: :cascade do |t|
    t.datetime "adopted_at"
    t.string "age_category", null: false
    t.date "birth_date"
    t.string "breed"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.boolean "good_with_cats"
    t.boolean "good_with_children"
    t.boolean "good_with_dogs"
    t.text "medical_notes"
    t.string "name", null: false
    t.jsonb "personality_traits", default: []
    t.jsonb "photo_order", default: []
    t.text "requirements"
    t.string "sex", null: false
    t.bigint "shelter_id", null: false
    t.string "size"
    t.boolean "spayed_neutered", default: false
    t.boolean "special_needs", default: false
    t.string "species", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.boolean "vaccinated", default: false
    t.index ["age_category"], name: "index_pets_on_age_category"
    t.index ["discarded_at"], name: "index_pets_on_discarded_at"
    t.index ["sex"], name: "index_pets_on_sex"
    t.index ["shelter_id"], name: "index_pets_on_shelter_id"
    t.index ["size"], name: "index_pets_on_size"
    t.index ["species"], name: "index_pets_on_species"
    t.index ["status"], name: "index_pets_on_status"
  end

  create_table "shelters", force: :cascade do |t|
    t.jsonb "adoption_policies", default: {}, null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "hours"
    t.string "name", null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.string "phone", null: false
    t.jsonb "species_served", default: ["dog"], null: false
    t.string "state", null: false
    t.string "status", default: "active", null: false
    t.string "street", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "zip", null: false
    t.index ["city"], name: "index_shelters_on_city"
    t.index ["discarded_at"], name: "index_shelters_on_discarded_at"
    t.index ["name"], name: "index_shelters_on_name", unique: true
    t.index ["species_served"], name: "index_shelters_on_species_served", using: :gin
    t.index ["state"], name: "index_shelters_on_state"
    t.index ["status"], name: "index_shelters_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "staff", null: false
    t.bigint "shelter_id"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["shelter_id"], name: "index_users_on_shelter_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "email_verification_tokens", "users"
  add_foreign_key "invitations", "shelters"
  add_foreign_key "invitations", "users", column: "created_by_id"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "pets", "shelters"
  add_foreign_key "users", "shelters"
end
