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

ActiveRecord::Schema[8.0].define(version: 2026_04_19_211000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cards", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "english_text", null: false
    t.string "spanish_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "part_of_speech", default: "noun", null: false
    t.index ["part_of_speech"], name: "index_cards_on_part_of_speech"
    t.index ["user_id", "english_text", "part_of_speech"], name: "index_cards_on_user_id_and_english_text_and_pos", unique: true
    t.index ["user_id"], name: "index_cards_on_user_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.integer "quiz_session_id", null: false
    t.integer "user_id", null: false
    t.integer "card_id", null: false
    t.string "prompt_text", null: false
    t.string "correct_choice", null: false
    t.string "selected_choice"
    t.boolean "correct", default: false, null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_quiz_attempts_on_card_id"
    t.index ["quiz_session_id", "position"], name: "index_quiz_attempts_on_quiz_session_id_and_position", unique: true
    t.index ["quiz_session_id"], name: "index_quiz_attempts_on_quiz_session_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quiz_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "mode", null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "question_count", default: 10, null: false
    t.index ["user_id"], name: "index_quiz_sessions_on_user_id"
  end

  create_table "user_card_stats", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "card_id", null: false
    t.integer "total_attempts", default: 0, null: false
    t.integer "correct_attempts", default: 0, null: false
    t.integer "incorrect_attempts", default: 0, null: false
    t.integer "streak", default: 0, null: false
    t.float "mastery_score", default: 0.0, null: false
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_user_card_stats_on_card_id"
    t.index ["user_id", "card_id"], name: "index_user_card_stats_on_user_id_and_card_id", unique: true
    t.index ["user_id"], name: "index_user_card_stats_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cards", "users"
  add_foreign_key "quiz_attempts", "cards"
  add_foreign_key "quiz_attempts", "quiz_sessions"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_sessions", "users"
  add_foreign_key "user_card_stats", "cards"
  add_foreign_key "user_card_stats", "users"
end
