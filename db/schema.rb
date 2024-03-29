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

ActiveRecord::Schema.define(version: 2023_01_20_192347) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "android_updates", id: :serial, force: :cascade do |t|
    t.integer "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "device_user_id"
    t.index ["device_user_id"], name: "index_api_keys_on_device_user_id"
  end

  create_table "back_translations", id: :serial, force: :cascade do |t|
    t.text "text"
    t.string "language"
    t.integer "backtranslatable_id"
    t.string "backtranslatable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approved"
    t.index ["backtranslatable_id", "backtranslatable_type", "language"], name: "backtranslatable_index", unique: true
  end

  create_table "centers", force: :cascade do |t|
    t.string "identifier"
    t.string "name"
    t.string "center_type"
    t.string "administration"
    t.string "region"
    t.string "department"
    t.string "municipality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_centers_on_identifier"
  end

  create_table "collages", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "condition_skips", id: :serial, force: :cascade do |t|
    t.integer "instrument_question_id"
    t.string "question_identifier"
    t.string "next_question_identifier"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "question_identifiers"
    t.text "option_ids"
    t.text "values"
    t.text "value_operators"
    t.index ["instrument_question_id"], name: "index_condition_skips_on_instrument_question_id"
  end

  create_table "critical_responses", id: :serial, force: :cascade do |t|
    t.string "question_identifier"
    t.string "option_identifier"
    t.integer "instruction_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instruction_id"], name: "index_critical_responses_on_instruction_id"
    t.index ["option_identifier"], name: "index_critical_responses_on_option_identifier"
    t.index ["question_identifier"], name: "index_critical_responses_on_question_identifier"
  end

  create_table "device_device_users", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.integer "device_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_sync_entries", id: :serial, force: :cascade do |t|
    t.string "latitude"
    t.string "longitude"
    t.integer "num_complete_surveys"
    t.string "current_language"
    t.string "current_version_code"
    t.text "instrument_versions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "device_uuid"
    t.string "api_key"
    t.string "timezone"
    t.string "current_version_name"
    t.string "os_build_number"
    t.integer "project_id"
    t.integer "num_incomplete_surveys"
    t.string "device_label"
  end

  create_table "device_users", id: :serial, force: :cascade do |t|
    t.string "username", null: false
    t.string "name"
    t.string "password_digest"
    t.boolean "active", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["username"], name: "index_device_users_on_username", unique: true
  end

  create_table "devices", id: :serial, force: :cascade do |t|
    t.string "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "label"
    t.index ["identifier"], name: "index_devices_on_identifier", unique: true
  end

  create_table "diagrams", force: :cascade do |t|
    t.integer "option_id"
    t.integer "position"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "collage_id"
    t.index ["collage_id"], name: "index_diagrams_on_collage_id"
    t.index ["option_id"], name: "index_diagrams_on_option_id"
  end

  create_table "display_instructions", id: :serial, force: :cascade do |t|
    t.integer "display_id"
    t.integer "instruction_id"
    t.integer "position"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "instrument_question_id"
  end

  create_table "display_translations", id: :serial, force: :cascade do |t|
    t.integer "display_id"
    t.text "text"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "displays", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "instrument_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
    t.datetime "deleted_at"
    t.integer "section_id"
    t.integer "instrument_questions_count"
    t.integer "instrument_position"
    t.index ["deleted_at"], name: "index_displays_on_deleted_at"
    t.index ["instrument_id"], name: "index_displays_on_instrument_id"
    t.index ["position"], name: "index_displays_on_position"
    t.index ["section_id"], name: "index_displays_on_section_id"
  end

  create_table "domain_scores", force: :cascade do |t|
    t.integer "domain_id"
    t.float "score_sum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "score_datum_id"
    t.index ["domain_id"], name: "index_domain_scores_on_domain_id"
    t.index ["score_datum_id"], name: "index_domain_scores_on_score_datum_id"
  end

  create_table "domain_translations", force: :cascade do |t|
    t.string "language"
    t.string "text"
    t.bigint "domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_domain_translations_on_domain_id"
  end

  create_table "domains", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "score_scheme_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "weight"
    t.string "name"
    t.index ["deleted_at"], name: "index_domains_on_deleted_at"
    t.index ["score_scheme_id"], name: "index_domains_on_score_scheme_id"
  end

  create_table "folders", id: :serial, force: :cascade do |t|
    t.integer "question_set_id"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["position"], name: "index_folders_on_position"
    t.index ["question_set_id"], name: "index_folders_on_question_set_id"
  end

  create_table "follow_up_questions", id: :serial, force: :cascade do |t|
    t.string "question_identifier"
    t.string "following_up_question_identifier"
    t.integer "position"
    t.integer "instrument_question_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grid_label_translations", id: :serial, force: :cascade do |t|
    t.integer "grid_label_id"
    t.integer "instrument_translation_id"
    t.text "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grid_labels", id: :serial, force: :cascade do |t|
    t.text "label"
    t.integer "grid_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "position"
  end

  create_table "grid_translations", id: :serial, force: :cascade do |t|
    t.integer "grid_id"
    t.integer "instrument_translation_id"
    t.string "name"
    t.text "instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grids", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.string "question_type"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "instructions"
    t.datetime "deleted_at"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "question_id"
    t.string "description"
    t.integer "number"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_images_on_deleted_at"
  end

  create_table "instruction_translations", id: :serial, force: :cascade do |t|
    t.integer "instruction_id"
    t.string "language"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instruction_id"], name: "index_instruction_translations_on_instruction_id"
    t.index ["language"], name: "index_instruction_translations_on_language"
  end

  create_table "instructions", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_instructions_on_deleted_at"
    t.index ["title"], name: "index_instructions_on_title", unique: true
  end

  create_table "instrument_questions", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "instrument_id"
    t.integer "number_in_instrument"
    t.integer "display_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "identifier"
    t.datetime "deleted_at"
    t.string "table_identifier"
    t.integer "loop_questions_count", default: 0
    t.string "carry_forward_identifier"
    t.integer "position"
    t.string "next_question_operator"
    t.string "multiple_skip_operator"
    t.text "next_question_neutral_ids"
    t.text "multiple_skip_neutral_ids"
    t.boolean "show_number", default: true
    t.index ["deleted_at"], name: "index_instrument_questions_on_deleted_at"
    t.index ["display_id"], name: "index_instrument_questions_on_display_id"
    t.index ["identifier"], name: "index_instrument_questions_on_identifier"
    t.index ["instrument_id", "identifier"], name: "index_instrument_questions_on_instrument_id_and_identifier"
    t.index ["instrument_id"], name: "index_instrument_questions_on_instrument_id"
    t.index ["number_in_instrument"], name: "index_instrument_questions_on_number_in_instrument"
    t.index ["position"], name: "index_instrument_questions_on_position"
    t.index ["question_id"], name: "index_instrument_questions_on_question_id"
  end

  create_table "instrument_rules", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.integer "rule_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "instrument_translations", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.string "language"
    t.string "alignment"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false
  end

  create_table "instruments", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "language"
    t.string "alignment"
    t.integer "instrument_questions_count", default: 0
    t.integer "project_id"
    t.boolean "published"
    t.datetime "deleted_at"
    t.boolean "require_responses", default: false
    t.boolean "scorable", default: false
    t.boolean "auto_export_responses", default: true
    t.index ["project_id", "title"], name: "index_instruments_on_project_id_and_title"
  end

  create_table "loop_questions", id: :serial, force: :cascade do |t|
    t.integer "instrument_question_id"
    t.string "parent"
    t.string "looped"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "option_indices"
    t.boolean "same_display", default: false
    t.text "replacement_text"
    t.index ["instrument_question_id"], name: "index_loop_questions_on_instrument_question_id"
  end

  create_table "metrics", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.string "name"
    t.integer "expected"
    t.string "key_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "multiple_skips", id: :serial, force: :cascade do |t|
    t.string "question_identifier"
    t.string "option_identifier"
    t.string "skip_question_identifier"
    t.integer "instrument_question_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.string "value_operator"
    t.index ["instrument_question_id"], name: "index_multiple_skips_on_instrument_question_id"
    t.index ["option_identifier"], name: "index_multiple_skips_on_option_identifier"
  end

  create_table "next_questions", id: :serial, force: :cascade do |t|
    t.string "question_identifier"
    t.string "option_identifier"
    t.string "next_question_identifier"
    t.integer "instrument_question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "value"
    t.boolean "complete_survey"
    t.string "value_operator"
    t.index ["instrument_question_id"], name: "index_next_questions_on_instrument_question_id"
    t.index ["option_identifier"], name: "index_next_questions_on_option_identifier"
  end

  create_table "option_collages", force: :cascade do |t|
    t.integer "option_in_option_set_id"
    t.integer "collage_id"
    t.integer "position"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collage_id"], name: "index_option_collages_on_collage_id"
    t.index ["option_in_option_set_id"], name: "index_option_collages_on_option_in_option_set_id"
  end

  create_table "option_in_option_sets", id: :serial, force: :cascade do |t|
    t.integer "option_id", null: false
    t.integer "option_set_id", null: false
    t.integer "number_in_question", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "special", default: false
    t.integer "instruction_id"
    t.boolean "allow_text_entry", default: false
    t.text "exclusion_ids"
    t.index ["instruction_id"], name: "index_option_in_option_sets_on_instruction_id"
    t.index ["number_in_question"], name: "index_option_in_option_sets_on_number_in_question"
    t.index ["option_id"], name: "index_option_in_option_sets_on_option_id"
    t.index ["option_set_id"], name: "index_option_in_option_sets_on_option_set_id"
  end

  create_table "option_scores", id: :serial, force: :cascade do |t|
    t.integer "score_unit_question_id"
    t.float "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "option_identifier"
    t.text "notes"
    t.index ["deleted_at"], name: "index_option_scores_on_deleted_at"
    t.index ["option_identifier"], name: "index_option_scores_on_option_identifier"
    t.index ["score_unit_question_id"], name: "index_option_scores_on_score_unit_question_id"
  end

  create_table "option_set_translations", id: :serial, force: :cascade do |t|
    t.integer "option_set_id"
    t.integer "option_translation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_set_id"], name: "index_option_set_translations_on_option_set_id"
    t.index ["option_translation_id"], name: "index_option_set_translations_on_option_translation_id"
  end

  create_table "option_sets", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "special", default: false
    t.datetime "deleted_at"
    t.integer "instruction_id"
    t.integer "option_in_option_sets_count", default: 0
    t.boolean "align_image_vertical", default: true
    t.index ["instruction_id"], name: "index_option_sets_on_instruction_id"
    t.index ["title"], name: "index_option_sets_on_title", unique: true
  end

  create_table "option_translations", id: :serial, force: :cascade do |t|
    t.integer "option_id"
    t.text "text"
    t.string "language"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "option_changed", default: false
    t.integer "instrument_translation_id"
    t.index ["language"], name: "index_option_translations_on_language"
    t.index ["option_id"], name: "index_option_translations_on_option_id"
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "identifier"
    t.index ["identifier"], name: "index_options_on_identifier"
  end

  create_table "project_device_users", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "device_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_devices", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "survey_aggregator"
  end

  create_table "question_collages", force: :cascade do |t|
    t.integer "question_id"
    t.integer "collage_id"
    t.integer "position"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collage_id"], name: "index_question_collages_on_collage_id"
    t.index ["question_id"], name: "index_question_collages_on_question_id"
  end

  create_table "question_randomized_factors", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "randomized_factor_id"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_sets", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_translations", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.string "language"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reg_ex_validation_message"
    t.boolean "question_changed", default: false
    t.text "instructions"
    t.integer "instrument_translation_id"
    t.index ["language"], name: "index_question_translations_on_language"
    t.index ["question_id"], name: "index_question_translations_on_question_id"
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.text "text"
    t.string "question_type"
    t.string "question_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean "identifies_survey", default: false
    t.integer "question_set_id"
    t.integer "option_set_id"
    t.integer "instruction_id"
    t.integer "special_option_set_id"
    t.string "parent_identifier"
    t.integer "folder_id"
    t.integer "validation_id"
    t.boolean "rank_responses", default: false
    t.integer "versions_count", default: 0
    t.integer "images_count", default: 0
    t.integer "pdf_response_height"
    t.boolean "pdf_print_options", default: true
    t.text "default_response"
    t.integer "position"
    t.integer "pop_up_instruction_id"
    t.integer "after_text_instruction_id"
    t.integer "task_id"
    t.boolean "record_audio", default: false
    t.index ["after_text_instruction_id"], name: "index_questions_on_after_text_instruction_id"
    t.index ["instruction_id"], name: "index_questions_on_instruction_id"
    t.index ["option_set_id"], name: "index_questions_on_option_set_id"
    t.index ["pop_up_instruction_id"], name: "index_questions_on_pop_up_instruction_id"
    t.index ["position"], name: "index_questions_on_position"
    t.index ["question_identifier"], name: "index_questions_on_question_identifier", unique: true
    t.index ["question_set_id"], name: "index_questions_on_question_set_id"
    t.index ["special_option_set_id"], name: "index_questions_on_special_option_set_id"
  end

  create_table "randomized_factors", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "randomized_option_translations", id: :serial, force: :cascade do |t|
    t.integer "instrument_translation_id"
    t.integer "randomized_option_id"
    t.text "text"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "randomized_options", id: :serial, force: :cascade do |t|
    t.integer "randomized_factor_id"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "raw_scores", id: :serial, force: :cascade do |t|
    t.integer "score_unit_id"
    t.integer "survey_score_id"
    t.float "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uuid"
    t.string "survey_score_uuid"
    t.datetime "deleted_at"
    t.integer "response_id"
    t.index ["response_id"], name: "index_raw_scores_on_response_id"
    t.index ["score_unit_id", "survey_score_id"], name: "index_raw_scores_on_score_unit_id_and_survey_score_id"
    t.index ["score_unit_id"], name: "index_raw_scores_on_score_unit_id"
    t.index ["survey_score_id"], name: "index_raw_scores_on_survey_score_id"
  end

  create_table "red_flags", force: :cascade do |t|
    t.integer "instrument_question_id"
    t.integer "instruction_id"
    t.string "option_identifier"
    t.boolean "selected", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "score_scheme_id"
    t.index ["instruction_id"], name: "index_red_flags_on_instruction_id"
    t.index ["instrument_question_id", "instruction_id", "option_identifier"], name: "instrument_question_instruction_option", unique: true
    t.index ["instrument_question_id"], name: "index_red_flags_on_instrument_question_id"
    t.index ["score_scheme_id"], name: "index_red_flags_on_score_scheme_id"
  end

  create_table "response_exports", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "instrument_id"
    t.text "instrument_versions"
    t.decimal "completion", precision: 5, scale: 2, default: "0.0"
  end

  create_table "response_images", id: :serial, force: :cascade do |t|
    t.string "response_uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "response_images_exports", id: :serial, force: :cascade do |t|
    t.integer "response_export_id"
    t.string "download_url"
    t.boolean "done", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "responses", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.text "text"
    t.text "other_response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "survey_uuid"
    t.string "special_response"
    t.datetime "time_started"
    t.datetime "time_ended"
    t.string "question_identifier"
    t.string "uuid"
    t.integer "device_user_id"
    t.integer "question_version", default: -1
    t.datetime "deleted_at"
    t.text "randomized_data"
    t.string "rank_order"
    t.text "other_text"
    t.index ["deleted_at"], name: "index_responses_on_deleted_at"
    t.index ["question_id"], name: "index_responses_on_question_id"
    t.index ["question_identifier"], name: "index_responses_on_question_identifier"
    t.index ["survey_uuid"], name: "index_responses_on_survey_uuid"
    t.index ["time_ended"], name: "index_responses_on_time_ended"
    t.index ["time_started"], name: "index_responses_on_time_started"
    t.index ["uuid"], name: "index_responses_on_uuid", unique: true
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "rosters", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "uuid"
    t.integer "instrument_id"
    t.string "identifier"
    t.string "instrument_title"
    t.integer "instrument_version_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rules", id: :serial, force: :cascade do |t|
    t.string "rule_type"
    t.string "rule_params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.time "deleted_at"
  end

  create_table "score_data", force: :cascade do |t|
    t.text "content"
    t.integer "survey_score_id"
    t.float "weight"
    t.string "operator"
    t.float "score_sum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_score_id", "operator", "weight"], name: "index_score_data_on_survey_score_id_and_operator_and_weight", unique: true
    t.index ["survey_score_id"], name: "index_score_data_on_survey_score_id"
  end

  create_table "score_scheme_centers", force: :cascade do |t|
    t.integer "center_id"
    t.integer "score_scheme_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["center_id"], name: "index_score_scheme_centers_on_center_id"
    t.index ["score_scheme_id"], name: "index_score_scheme_centers_on_score_scheme_id"
  end

  create_table "score_schemes", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean "active"
    t.integer "progress", default: 0
    t.index ["deleted_at"], name: "index_score_schemes_on_deleted_at"
  end

  create_table "score_unit_questions", id: :serial, force: :cascade do |t|
    t.integer "score_unit_id"
    t.integer "instrument_question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_score_unit_questions_on_deleted_at"
    t.index ["instrument_question_id"], name: "index_score_unit_questions_on_instrument_question_id"
    t.index ["score_unit_id"], name: "index_score_unit_questions_on_score_unit_id"
  end

  create_table "score_units", id: :serial, force: :cascade do |t|
    t.float "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "score_type"
    t.datetime "deleted_at"
    t.integer "subdomain_id"
    t.string "title"
    t.float "base_point_score"
    t.string "institution_type"
    t.text "notes"
    t.index ["deleted_at"], name: "index_score_units_on_deleted_at"
    t.index ["subdomain_id"], name: "index_score_units_on_subdomain_id"
    t.index ["title"], name: "index_score_units_on_title"
  end

  create_table "section_translations", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.string "language"
    t.string "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "section_changed", default: false
    t.integer "instrument_translation_id"
    t.index ["language"], name: "index_section_translations_on_language"
    t.index ["section_id"], name: "index_section_translations_on_section_id"
  end

  create_table "sections", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "instrument_id"
    t.datetime "deleted_at"
    t.integer "position"
    t.boolean "randomize_displays", default: false
    t.index ["deleted_at"], name: "index_sections_on_deleted_at"
    t.index ["instrument_id", "title"], name: "index_sections_on_instrument_id_and_title"
    t.index ["instrument_id"], name: "index_sections_on_instrument_id"
    t.index ["position"], name: "index_sections_on_position"
  end

  create_table "skip_patterns", id: :serial, force: :cascade do |t|
    t.string "option_identifier"
    t.string "question_identifier"
    t.string "next_question_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skips", id: :serial, force: :cascade do |t|
    t.integer "option_id"
    t.string "question_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_skips_on_deleted_at"
  end

  create_table "stats", id: :serial, force: :cascade do |t|
    t.integer "metric_id"
    t.string "key_value"
    t.integer "count"
    t.string "percent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subdomain_scores", force: :cascade do |t|
    t.integer "subdomain_id"
    t.float "score_sum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "score_datum_id"
    t.index ["score_datum_id"], name: "index_subdomain_scores_on_score_datum_id"
    t.index ["subdomain_id"], name: "index_subdomain_scores_on_subdomain_id"
  end

  create_table "subdomain_translations", force: :cascade do |t|
    t.string "language"
    t.string "text"
    t.bigint "subdomain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "alt_text"
    t.index ["subdomain_id"], name: "index_subdomain_translations_on_subdomain_id"
  end

  create_table "subdomains", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "domain_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "weight"
    t.string "name"
    t.string "alt_text"
    t.index ["deleted_at"], name: "index_subdomains_on_deleted_at"
    t.index ["domain_id"], name: "index_subdomains_on_domain_id"
  end

  create_table "survey_exports", force: :cascade do |t|
    t.integer "survey_id"
    t.text "long"
    t.text "short"
    t.text "wide"
    t.datetime "last_response_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "survey_notes", force: :cascade do |t|
    t.string "uuid"
    t.string "survey_uuid"
    t.integer "device_user_id"
    t.string "reference"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_uuid"], name: "index_survey_notes_on_survey_uuid"
    t.index ["uuid"], name: "index_survey_notes_on_uuid"
  end

  create_table "survey_scores", id: :serial, force: :cascade do |t|
    t.integer "survey_id"
    t.integer "score_scheme_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uuid"
    t.string "survey_uuid"
    t.string "device_uuid"
    t.string "device_label"
    t.datetime "deleted_at"
    t.string "identifier"
    t.index ["identifier"], name: "index_survey_scores_on_identifier"
    t.index ["survey_id", "score_scheme_id"], name: "index_survey_scores_on_survey_id_and_score_scheme_id"
  end

  create_table "surveys", id: :serial, force: :cascade do |t|
    t.integer "instrument_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uuid"
    t.integer "device_id"
    t.integer "instrument_version_number"
    t.string "instrument_title"
    t.string "device_uuid"
    t.string "latitude"
    t.string "longitude"
    t.text "metadata"
    t.string "completion_rate"
    t.string "device_label"
    t.datetime "deleted_at"
    t.string "language"
    t.text "skipped_questions"
    t.integer "completed_responses_count"
    t.integer "device_user_id"
    t.boolean "completed", default: false
    t.index ["deleted_at"], name: "index_surveys_on_deleted_at"
    t.index ["instrument_id"], name: "index_surveys_on_instrument_id"
    t.index ["uuid"], name: "index_surveys_on_uuid", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_option_sets", force: :cascade do |t|
    t.integer "task_id"
    t.integer "option_set_id"
    t.integer "position"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_projects", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_user_projects_on_project_id"
    t.index ["user_id"], name: "index_user_projects_on_user_id"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "gauth_secret"
    t.string "gauth_enabled", default: "f"
    t.string "gauth_tmp"
    t.datetime "gauth_tmp_datetime"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "password_digest"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "validation_translations", id: :serial, force: :cascade do |t|
    t.integer "validation_id"
    t.string "language"
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "validations", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "validation_text"
    t.string "validation_message"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "validation_type"
    t.string "response_identifier"
    t.string "relational_operator"
  end

  create_table "version_associations", id: :serial, force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

end
