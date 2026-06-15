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

ActiveRecord::Schema[8.1].define(version: 2026_06_15_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "email_verification_tokens", "users"
  add_foreign_key "password_reset_tokens", "users"
end
