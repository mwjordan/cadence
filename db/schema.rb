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

ActiveRecord::Schema[8.1].define(version: 2026_10_25_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "check_ins", force: :cascade do |t|
    t.bigint "commitment_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "due_at", null: false
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commitment_id"], name: "index_check_ins_on_commitment_id"
    t.index ["commitment_id"], name: "one_open_check_in_per_commitment", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'snoozed'::character varying])::text[]))"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'snoozed'::character varying, 'done'::character varying, 'skipped'::character varying, 'canceled'::character varying]::text[])", name: "check_in_status_values"
  end

  create_table "commitments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.integer "interval_minutes", default: 120, null: false
    t.boolean "active", default: true, null: false
    t.datetime "next_due_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "next_due_at"], name: "index_commitments_on_active_and_next_due_at"
    t.index ["user_id"], name: "index_commitments_on_user_id"
    t.check_constraint "interval_minutes >= 1 AND interval_minutes <= 1440", name: "commitment_interval_range"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "check_ins", "commitments"
  add_foreign_key "commitments", "users"
end
