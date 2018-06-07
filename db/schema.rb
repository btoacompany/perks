# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  create_table "admins", force: :cascade do |t|
    t.string   "name",        limit: 191,             null: false
    t.string   "firstname",   limit: 191
    t.string   "lastname",    limit: 191
    t.string   "email",       limit: 191,             null: false
    t.integer  "gender",      limit: 1,   default: 0
    t.integer  "admin_type",  limit: 1,   default: 0
    t.string   "password",    limit: 191,             null: false
    t.string   "salt",        limit: 191,             null: false
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0, null: false
  end

  add_index "admins", ["email"], name: "email", unique: true, using: :btree

  create_table "bonus", force: :cascade do |t|
    t.string   "title",       limit: 191,               null: false
    t.integer  "company_id",  limit: 4,                 null: false
    t.string   "img_src",     limit: 191
    t.text     "description", limit: 65535
    t.integer  "points",      limit: 4,     default: 0, null: false
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag", limit: 1,     default: 0, null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "company_id",  limit: 4,                 null: false
    t.integer  "user_id",     limit: 4,                 null: false
    t.integer  "post_id",     limit: 4,                 null: false
    t.text     "comments",    limit: 65535
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag", limit: 1,     default: 0
  end

  create_table "company", force: :cascade do |t|
    t.string   "name",              limit: 191,               null: false
    t.string   "owner",             limit: 191,               null: false
    t.string   "email",             limit: 191,               null: false
    t.string   "address",           limit: 191
    t.string   "phone",             limit: 191
    t.string   "url",               limit: 191
    t.string   "logo",              limit: 191
    t.string   "hashtags",          limit: 191
    t.integer  "points_default",    limit: 4,     default: 0
    t.integer  "bonus_points",      limit: 4,     default: 0
    t.integer  "bonus_default",     limit: 4,     default: 0
    t.integer  "plan",              limit: 1,     default: 0, null: false
    t.integer  "plan_approved",     limit: 1,     default: 0, null: false
    t.datetime "plan_start_date"
    t.integer  "verified",          limit: 1,     default: 0, null: false
    t.string   "password",          limit: 191
    t.string   "salt",              limit: 191
    t.integer  "user_id",           limit: 4,     default: 0
    t.integer  "invite_email_flag", limit: 1,     default: 0
    t.integer  "point_fixed_flag",  limit: 1,     default: 0
    t.integer  "fixed_point",       limit: 4
    t.integer  "ip_limit_flag",     limit: 1,     default: 0
    t.text     "allowed_ips",       limit: 65535
    t.date     "reset_point_date"
    t.datetime "create_time",                                 null: false
    t.datetime "update_time",                                 null: false
    t.integer  "delete_flag",       limit: 1,     default: 0, null: false
  end

  add_index "company", ["email"], name: "email", unique: true, using: :btree

  create_table "condition_scores", force: :cascade do |t|
    t.integer  "team_id",            limit: 4,                null: false
    t.integer  "user_id",            limit: 4,                null: false
    t.float    "boss_relation",      limit: 24, default: 0.0, null: false
    t.float    "colleague_relation", limit: 24, default: 0.0, null: false
    t.float    "work_meaning",       limit: 24, default: 0.0, null: false
    t.float    "work_environment",   limit: 24, default: 0.0, null: false
    t.float    "growth_score",       limit: 24, default: 0.0, null: false
    t.float    "stress_score",       limit: 24, default: 0.0, null: false
    t.float    "total_score",        limit: 24, default: 0.0, null: false
    t.datetime "create_time",                                 null: false
    t.datetime "update_time",                                 null: false
    t.integer  "delete_flag",        limit: 1,  default: 0,   null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string   "dep_name",    limit: 191,             null: false
    t.integer  "company_id",  limit: 4,               null: false
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0
  end

  create_table "hashtags", force: :cascade do |t|
    t.integer  "post_id",     limit: 4,               null: false
    t.integer  "company_id",  limit: 4,               null: false
    t.integer  "user_id",     limit: 4,               null: false
    t.integer  "receiver_id", limit: 4,               null: false
    t.string   "hashtag",     limit: 191
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0
  end

  create_table "invite_link", force: :cascade do |t|
    t.integer  "company_id",  limit: 4,               null: false
    t.string   "c_code",      limit: 255,             null: false
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0
  end

  create_table "ios_tokens", primary_key: "token", force: :cascade do |t|
    t.string "user_id", limit: 191, null: false
    t.string "arn",     limit: 191, null: false
  end

  create_table "kudos", force: :cascade do |t|
    t.integer  "post_id",     limit: 4,             null: false
    t.integer  "user_id",     limit: 4,             null: false
    t.integer  "kudos",       limit: 1, default: 0
    t.datetime "create_time",                       null: false
    t.datetime "update_time",                       null: false
    t.integer  "delete_flag", limit: 1, default: 0
  end

  create_table "posts", force: :cascade do |t|
    t.integer  "company_id",  limit: 4,               null: false
    t.integer  "user_id",     limit: 4,               null: false
    t.integer  "receiver_id", limit: 4,               null: false
    t.integer  "points",      limit: 4,   default: 0
    t.string   "description", limit: 191
    t.integer  "privacy",     limit: 1,   default: 0, null: false
    t.integer  "post_type",   limit: 1,   default: 0, null: false
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0
  end

  create_table "pv", force: :cascade do |t|
    t.integer  "company_id",  limit: 4,               null: false
    t.integer  "user_id",     limit: 4,               null: false
    t.integer  "team_id",     limit: 4,   default: 0, null: false
    t.string   "page_path",   limit: 255
    t.integer  "pv_count",    limit: 4,   default: 0, null: false
    t.date     "track_date",                          null: false
    t.datetime "create_time",                         null: false
  end

# Could not dump table "relationship_scores" because of following StandardError
#   Unknown type 'json' for column 'scores'

  create_table "request_rewards", force: :cascade do |t|
    t.integer  "company_id",      limit: 4,             null: false
    t.integer  "user_id",         limit: 4,             null: false
    t.integer  "reward_id",       limit: 4, default: 0
    t.integer  "reward_prizy_id", limit: 4, default: 0
    t.integer  "status",          limit: 1, default: 0
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag",     limit: 1, default: 0
  end

  create_table "rewards", force: :cascade do |t|
    t.string   "title",       limit: 191,               null: false
    t.integer  "company_id",  limit: 4,                 null: false
    t.string   "img_src",     limit: 191
    t.string   "url",         limit: 191
    t.integer  "category_id", limit: 4,     default: 0, null: false
    t.text     "description", limit: 65535
    t.integer  "points",      limit: 4,     default: 0, null: false
    t.integer  "plan",        limit: 1,     default: 0, null: false
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag", limit: 1,     default: 0, null: false
  end

  create_table "rewards_prizy", force: :cascade do |t|
    t.string   "title",       limit: 191,               null: false
    t.string   "img_src",     limit: 191
    t.string   "url",         limit: 191
    t.integer  "category_id", limit: 4,     default: 0, null: false
    t.text     "description", limit: 65535
    t.integer  "points",      limit: 4,     default: 0, null: false
    t.integer  "plan",        limit: 1,     default: 0, null: false
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag", limit: 1,     default: 0, null: false
  end

  create_table "slack_tokens", primary_key: "token", force: :cascade do |t|
    t.string "team_id",      limit: 191, null: false
    t.string "webhooks_url", limit: 191
    t.string "bot_token",    limit: 191
  end

  create_table "team_scores", force: :cascade do |t|
    t.integer  "team_id",          limit: 4,                null: false
    t.integer  "manager_id",       limit: 4,                null: false
    t.float    "team_score",       limit: 24, default: 0.0, null: false
    t.float    "management_score", limit: 24, default: 0.0, null: false
    t.datetime "create_time",                               null: false
    t.datetime "update_time",                               null: false
    t.integer  "delete_flag",      limit: 1,  default: 0,   null: false
  end

  create_table "teams", force: :cascade do |t|
    t.integer  "department_id", limit: 4,               null: false
    t.string   "team_name",     limit: 191,             null: false
    t.integer  "company_id",    limit: 4,               null: false
    t.integer  "manager_id",    limit: 4,               null: false
    t.string   "member_ids",    limit: 191,             null: false
    t.datetime "create_time",                           null: false
    t.datetime "update_time",                           null: false
    t.integer  "delete_flag",   limit: 1,   default: 0
  end

  create_table "tests", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "email",       limit: 255
    t.datetime "create_time",                         null: false
    t.datetime "update_time",                         null: false
    t.integer  "delete_flag", limit: 1,   default: 0, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",         limit: 191
    t.string   "firstname",    limit: 191
    t.string   "lastname",     limit: 191
    t.string   "email",        limit: 191,             null: false
    t.date     "birthday"
    t.integer  "gender",       limit: 1,   default: 0, null: false
    t.string   "img_src",      limit: 191
    t.string   "job_title",    limit: 191
    t.integer  "company_id",   limit: 4,               null: false
    t.integer  "in_points",    limit: 4,   default: 0, null: false
    t.integer  "out_points",   limit: 4,   default: 0, null: false
    t.integer  "kudos",        limit: 4,   default: 0, null: false
    t.integer  "plan",         limit: 1,   default: 0, null: false
    t.integer  "verified",     limit: 1,   default: 0, null: false
    t.string   "password",     limit: 191
    t.string   "salt",         limit: 191
    t.integer  "admin",        limit: 1,   default: 0
    t.integer  "member_flag",  limit: 1,   default: 0
    t.integer  "manager_flag", limit: 1,   default: 0
    t.datetime "create_time",                          null: false
    t.datetime "update_time",                          null: false
    t.integer  "delete_flag",  limit: 1,   default: 0, null: false
  end

  add_index "users", ["email"], name: "email", unique: true, using: :btree

end
