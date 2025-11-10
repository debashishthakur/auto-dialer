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

ActiveRecord::Schema[7.0].define(version: 2024_10_19_120100) do
  create_table "calls", force: :cascade do |t|
    t.integer "phone_number_id", null: false
    t.string "call_sid"
    t.integer "status", default: 0, null: false
    t.integer "duration"
    t.text "recording_url"
    t.text "voice_script"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["call_sid"], name: "index_calls_on_call_sid", unique: true
    t.index ["phone_number_id"], name: "index_calls_on_phone_number_id"
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "number", null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_phone_numbers_on_number", unique: true
  end

  add_foreign_key "calls", "phone_numbers"
end
