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

ActiveRecord::Schema.define(version: 20170217154033) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "android_updates", force: true do |t|
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "apk_update_file_name"
    t.string   "apk_update_content_type"
    t.integer  "apk_update_file_size"
    t.datetime "apk_update_updated_at"
  end

  create_table "api_keys", force: true do |t|
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_device_users", force: true do |t|
    t.integer  "device_id"
    t.integer  "device_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_sync_entries", force: true do |t|
    t.string   "latitude"
    t.string   "longitude"
    t.integer  "num_complete_surveys"
    t.string   "current_language"
    t.string   "current_version_code"
    t.text     "instrument_versions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "device_uuid"
    t.string   "api_key"
    t.string   "timezone"
    t.string   "current_version_name"
    t.string   "os_build_number"
    t.integer  "project_id"
    t.integer  "num_incomplete_surveys"
  end

  create_table "device_users", force: true do |t|
    t.string   "username",                        null: false
    t.string   "name"
    t.string   "password_digest"
    t.boolean  "active",          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devices", force: true do |t|
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label"
  end

  add_index "devices", ["identifier"], name: "index_devices_on_identifier", unique: true

  create_table "grid_labels", force: true do |t|
    t.text     "label"
    t.integer  "grid_id"
    t.integer  "option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grids", force: true do |t|
    t.integer  "instrument_id"
    t.string   "question_type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "question_id"
    t.string   "description"
    t.integer  "number"
  end

  create_table "instrument_translations", force: true do |t|
    t.integer  "instrument_id"
    t.string   "language"
    t.string   "alignment"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "critical_message"
  end

  create_table "instruments", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language"
    t.string   "alignment"
    t.integer  "child_update_count",      default: 0
    t.integer  "previous_question_count"
    t.integer  "project_id"
    t.boolean  "published"
    t.datetime "deleted_at"
    t.boolean  "show_instructions",       default: false
    t.text     "special_options"
    t.boolean  "show_sections_page",      default: false
    t.boolean  "navigate_to_review_page", default: false
    t.text     "critical_message"
    t.boolean  "roster",                  default: false
    t.string   "roster_type"
  end

  create_table "metrics", force: true do |t|
    t.integer  "instrument_id"
    t.string   "name"
    t.integer  "expected"
    t.string   "key_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "option_scores", force: true do |t|
    t.integer  "score_unit_id"
    t.integer  "option_id"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label"
    t.boolean  "exists"
  end

  create_table "option_translations", force: true do |t|
    t.integer  "option_id"
    t.text     "text"
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "option_changed", default: false
  end

  create_table "options", force: true do |t|
    t.integer  "question_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "next_question"
    t.integer  "number_in_question"
    t.datetime "deleted_at"
    t.integer  "instrument_version_number", default: -1
    t.boolean  "special",                   default: false
    t.boolean  "critical"
  end

  create_table "project_device_users", force: true do |t|
    t.integer  "project_id"
    t.integer  "device_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_devices", force: true do |t|
    t.integer  "project_id"
    t.integer  "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_translations", force: true do |t|
    t.integer  "question_id"
    t.string   "language"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reg_ex_validation_message"
    t.boolean  "question_changed",          default: false
    t.text     "instructions"
  end

  create_table "questions", force: true do |t|
    t.text     "text"
    t.string   "question_type"
    t.string   "question_identifier"
    t.integer  "instrument_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "following_up_question_identifier"
    t.string   "reg_ex_validation"
    t.integer  "number_in_instrument"
    t.string   "reg_ex_validation_message"
    t.datetime "deleted_at"
    t.integer  "follow_up_position",               default: 0
    t.boolean  "identifies_survey",                default: false
    t.text     "instructions",                     default: ""
    t.integer  "child_update_count",               default: 0
    t.integer  "grid_id"
    t.boolean  "first_in_grid",                    default: false
    t.integer  "instrument_version_number",        default: -1
    t.integer  "section_id"
    t.boolean  "critical"
  end

  add_index "questions", ["question_identifier"], name: "index_questions_on_question_identifier", unique: true

  create_table "raw_scores", force: true do |t|
    t.integer  "score_unit_id"
    t.integer  "score_id"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "response_exports", force: true do |t|
    t.string   "long_format_url"
    t.boolean  "long_done",           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.integer  "instrument_id"
    t.text     "instrument_versions"
    t.string   "wide_format_url"
    t.boolean  "wide_done",           default: false
    t.string   "short_format_url"
    t.boolean  "short_done",          default: false
  end

  create_table "response_images", force: true do |t|
    t.string   "response_uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
  end

  create_table "response_images_exports", force: true do |t|
    t.integer  "response_export_id"
    t.string   "download_url"
    t.boolean  "done",               default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "responses", force: true do |t|
    t.integer  "question_id"
    t.text     "text"
    t.text     "other_response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "survey_uuid"
    t.string   "special_response"
    t.datetime "time_started"
    t.datetime "time_ended"
    t.string   "question_identifier"
    t.string   "uuid"
    t.integer  "device_user_id"
    t.integer  "question_version",    default: -1
    t.datetime "deleted_at"
  end

  add_index "responses", ["deleted_at"], name: "index_responses_on_deleted_at"
  add_index "responses", ["uuid"], name: "index_responses_on_uuid"

  create_table "roles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rosters", force: true do |t|
    t.integer  "project_id"
    t.string   "uuid"
    t.integer  "instrument_id"
    t.string   "identifier"
    t.string   "instrument_title"
    t.integer  "instrument_version_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rules", force: true do |t|
    t.string   "rule_type"
    t.integer  "instrument_id"
    t.string   "rule_params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.time     "deleted_at"
  end

  create_table "score_schemes", force: true do |t|
    t.string   "instrument_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "score_sections", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "instrument_id"
  end

  create_table "score_sub_sections", force: true do |t|
    t.string   "name"
    t.integer  "score_section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "score_unit_questions", force: true do |t|
    t.integer  "score_unit_id"
    t.integer  "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "score_units", force: true do |t|
    t.integer  "score_scheme_id"
    t.string   "question_type"
    t.float    "min"
    t.float    "max"
    t.float    "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "score_type"
  end

  create_table "scores", force: true do |t|
    t.integer  "survey_id"
    t.integer  "score_scheme_id"
    t.float    "score_sum"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "section_translations", force: true do |t|
    t.integer  "section_id"
    t.string   "language"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "section_changed", default: false
  end

  create_table "sections", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "instrument_id"
    t.datetime "deleted_at"
  end

  add_index "sections", ["deleted_at"], name: "index_sections_on_deleted_at"

  create_table "skips", force: true do |t|
    t.integer  "option_id"
    t.string   "question_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "skips", ["deleted_at"], name: "index_skips_on_deleted_at"

  create_table "stats", force: true do |t|
    t.integer  "metric_id"
    t.string   "key_value"
    t.integer  "count"
    t.string   "percent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "survey_scores", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "survey_id"
    t.string   "survey_uuid"
    t.string   "device_label"
    t.string   "device_user"
    t.string   "survey_start_time"
    t.string   "survey_end_time"
    t.string   "center_id"
  end

  create_table "surveys", force: true do |t|
    t.integer  "instrument_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.integer  "device_id"
    t.integer  "instrument_version_number"
    t.string   "instrument_title"
    t.string   "device_uuid"
    t.string   "latitude"
    t.string   "longitude"
    t.text     "metadata"
    t.string   "completion_rate",           limit: 3
    t.string   "device_label"
    t.datetime "deleted_at"
    t.boolean  "has_critical_responses"
    t.string   "roster_uuid"
  end

  add_index "surveys", ["deleted_at"], name: "index_surveys_on_deleted_at"
  add_index "surveys", ["uuid"], name: "index_surveys_on_uuid"

  create_table "unit_scores", force: true do |t|
    t.integer  "survey_score_id"
    t.integer  "unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "value"
    t.integer  "variable_id"
    t.string   "center_section_sub_section_name"
    t.string   "center_section_name"
  end

  create_table "units", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "weight"
    t.integer  "score_sub_section_id"
    t.string   "domain"
    t.string   "sub_domain"
  end

  create_table "user_projects", force: true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",  null: false
    t.string   "encrypted_password",     default: "",  null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,   null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "last_active_at"
    t.string   "gauth_secret"
    t.string   "gauth_enabled",          default: "f"
    t.string   "gauth_tmp"
    t.datetime "gauth_tmp_datetime"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "variables", force: true do |t|
    t.string   "name"
    t.integer  "value"
    t.string   "next_variable"
    t.integer  "unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "result"
    t.string   "next_unit_name"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

end
