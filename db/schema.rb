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

ActiveRecord::Schema[8.0].define(version: 2025_06_26_050436) do
  create_table "follows", charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "target_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_user_id"], name: "index_follows_on_target_user_id"
    t.index ["user_id", "target_user_id"], name: "index_follows_on_user_id_and_target_user_id", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "sleep_logs", charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "clock_out"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "clock_in", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["user_id", "clock_in"], name: "index_sleep_logs_on_user_id_and_clock_in", order: { clock_in: :desc }
    t.index ["user_id", "clock_out"], name: "index_sleep_logs_on_user_id_and_clock_out"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "num_following", default: 0, null: false
    t.integer "num_followers", default: 0, null: false
    t.datetime "last_backfill_at"
    t.index ["name"], name: "index_users_on_name", unique: true
  end
end
