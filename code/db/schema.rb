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

ActiveRecord::Schema[8.1].define(version: 2026_05_02_000003) do
  create_table "forums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_member_id", null: false
    t.datetime "deleted_at"
    t.string "name", limit: 50, null: false
    t.boolean "nsfw", default: false, null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(name)", name: "idx_forums_lower_name", unique: true
    t.index ["created_by_member_id"], name: "index_forums_on_created_by_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.integer "access_level", default: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "display_name", limit: 50, null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(display_name)", name: "idx_members_lower_display_name", unique: true
    t.index "LOWER(email)", name: "idx_members_lower_email", unique: true
    t.check_constraint "access_level IN (100, 200, 300)", name: "chk_members_access_level"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "forum_id"
    t.integer "member_id", null: false
    t.integer "parent_post_id"
    t.string "title", limit: 200
    t.datetime "updated_at", null: false
    t.index ["forum_id"], name: "index_posts_on_forum_id"
    t.index ["member_id"], name: "index_posts_on_member_id"
    t.index ["parent_post_id"], name: "index_posts_on_parent_post_id"
    t.check_constraint "(forum_id IS NOT NULL AND parent_post_id IS NULL AND title IS NOT NULL) OR (forum_id IS NULL AND parent_post_id IS NOT NULL AND title IS NULL)", name: "chk_posts_thread_or_reply"
  end

  add_foreign_key "forums", "members", column: "created_by_member_id", on_delete: :restrict
  add_foreign_key "posts", "forums", on_delete: :restrict
  add_foreign_key "posts", "members", on_delete: :restrict
  add_foreign_key "posts", "posts", column: "parent_post_id", on_delete: :restrict
end
