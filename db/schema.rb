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

ActiveRecord::Schema.define(version: 20190517071722) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "uuid-ossp"

  create_table "activity_permissions", force: :cascade do |t|
    t.string   "permissible_type"
    t.integer  "permissible_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "topic_id"
    t.string   "type",             default: "DomainPermission"
    t.text     "access_hash",      default: "--- {}\n"
  end

  create_table "attachments", force: :cascade do |t|
    t.string   "file"
    t.string   "type"
    t.string   "attachable_type",    index: {name: "index_attachments_on_attachable", with: ["attachable_id"]}
    t.integer  "attachable_id"
    t.boolean  "file_processing"
    t.string   "file_tmp"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "user_id",            index: {name: "index_attachments_on_user_id"}
    t.string   "zencoder_output_id"
    t.boolean  "zencoder_processed", default: false
    t.integer  "old_resource_id"
    t.string   "original_url"
    t.text     "messages"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id",     index: {name: "index_comments_on_commentable_id_and_commentable_type", with: ["commentable_type"]}
    t.string   "commentable_type"
    t.string   "title"
    t.text     "body"
    t.string   "subject"
    t.integer  "user_id",            null: false, index: {name: "index_comments_on_user_id"}
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.float    "longitude"
    t.float    "latitude"
    t.string   "address"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message_identifier"
  end

  create_table "contact_informations", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "address"
    t.string   "appartment"
    t.string   "city"
    t.string   "country"
    t.string   "state"
    t.string   "zip"
    t.integer  "subscription_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "domain_id"
  end

  create_table "context_tips", force: :cascade do |t|
    t.string   "context_id"
    t.integer  "tip_id",     null: false, index: {name: "index_context_tips_on_tip_id"}
    t.integer  "position",   index: {name: "index_context_tips_on_position"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "context_topics", force: :cascade do |t|
    t.string   "context_id"
    t.integer  "topic_id",   null: false, index: {name: "index_context_topics_on_topic_id"}
    t.integer  "position",   index: {name: "index_context_topics_on_position"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contexts", id: false, force: :cascade do |t|
    t.string   "context_uniq_id", null: false, index: {name: "index_contexts_on_context_uniq_id", unique: true}
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "name"
    t.boolean  "default",         default: false
    t.integer  "topic_id"
  end

  create_table "domain_memberships", force: :cascade do |t|
    t.integer  "user_id",         null: false, index: {name: "index_domain_memberships_on_user_id"}
    t.integer  "domain_id",       null: false, index: {name: "index_domain_memberships_on_domain_id"}
    t.string   "role",            default: "member", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "invitation_id",   index: {name: "index_domain_memberships_on_invitation_id"}
    t.boolean  "active",          default: true,     null: false
    t.string   "upgrade_to_role"
  end

  create_table "domains", force: :cascade do |t|
    t.integer  "user_id",                     null: false, index: {name: "index_domains_on_user_id"}
    t.string   "name"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "tenant_name",                 null: false, index: {name: "index_domains_on_tenant_name", unique: true, case_sensitive: false}
    t.string   "logo"
    t.string   "logo_tmp"
    t.boolean  "logo_processing"
    t.string   "background_image"
    t.string   "background_image_tmp"
    t.boolean  "background_image_processing"
    t.boolean  "is_public",                   default: false
    t.integer  "join_type",                   default: 0,     null: false
    t.string   "email_domains"
    t.boolean  "allow_invitation_request",    default: false, null: false
    t.boolean  "sso_enabled",                 default: false
    t.string   "idp_entity_id"
    t.string   "idp_sso_target_url"
    t.string   "idp_slo_target_url"
    t.text     "idp_cert"
    t.string   "issuer"
    t.string   "default_view_id"
    t.boolean  "is_disabled",                 default: false
    t.boolean  "is_deleted",                  default: false
    t.string   "stripe_customer_id"
    t.string   "stripe_card_id"
    t.string   "color"
  end

  create_table "flags", force: :cascade do |t|
    t.integer  "flaggable_id",   index: {name: "index_flags_on_flaggable_id"}
    t.string   "flaggable_type", index: {name: "index_flags_on_flaggable_type"}
    t.string   "reason"
    t.integer  "flagger_id",     index: {name: "index_flags_on_flagger_id"}
    t.string   "flagger_type",   index: {name: "index_flags_on_flagger_type"}
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "follows", force: :cascade do |t|
    t.integer  "followable_id",   null: false, index: {name: "fk_followables", with: ["followable_type"]}
    t.string   "followable_type", null: false
    t.integer  "follower_id",     null: false, index: {name: "fk_follows", with: ["follower_type"]}
    t.string   "follower_type",   null: false
    t.boolean  "blocked",         default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "global_templates", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "template_type"
    t.string   "title"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "user_id",                     null: false, index: {name: "index_groups_on_user_id"}
    t.string   "title",                       index: {name: "index_groups_on_title", case_sensitive: false}
    t.text     "description"
    t.string   "join_type"
    t.string   "group_type"
    t.integer  "color_index"
    t.string   "background_image"
    t.integer  "image_top"
    t.integer  "image_left"
    t.string   "address"
    t.string   "location"
    t.string   "zip"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "avatar"
    t.string   "admin_ids"
    t.boolean  "is_auto_accept"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "avatar_tmp"
    t.boolean  "avatar_processing"
    t.string   "background_image_tmp"
    t.boolean  "background_image_processing"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer  "user_id",          null: false, index: {name: "index_invitations_on_user_id"}
    t.string   "email"
    t.string   "invitation_token"
    t.string   "invitation_type"
    t.string   "invitable_type"
    t.integer  "invitable_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.text     "custom_message"
    t.string   "state",            default: "pending"
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "do_not_remind",    default: false
    t.datetime "daily_sent_at"
    t.jsonb    "options",          default: {},        null: false, index: {name: "index_invitations_on_options", using: :gin}
  end

  create_table "label_assignments", force: :cascade do |t|
    t.integer  "label_id",   index: {name: "index_label_assignments_on_label_id"}
    t.integer  "item_id"
    t.string   "item_type",  index: {name: "index_label_assignments_on_item_type_and_item_id", with: ["item_id"]}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "label_categories", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "label_orders", force: :cascade do |t|
    t.string   "name"
    t.integer  "order",      default: [],              array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "is_default"
  end

  create_table "labels", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "color",      index: {name: "index_labels_on_color"}
    t.string   "kind",       index: {name: "index_labels_on_kind"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "labels_label_categories", id: false, force: :cascade do |t|
    t.integer "label_id",          index: {name: "index_labels_label_categories_on_label_id"}
    t.integer "label_category_id", index: {name: "index_labels_label_categories_on_label_category_id"}
  end

  create_table "lists", force: :cascade do |t|
    t.integer  "user_id",    null: false, index: {name: "index_lists_on_user_id"}
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mentions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mentionable_id"
    t.string   "mentionable_type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "notifier_id"
    t.string   "type"
    t.string   "action"
    t.string   "notifiable_type", index: {name: "index_notifications_on_notifiable_type_and_notifiable_id", with: ["notifiable_id"]}
    t.integer  "notifiable_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.datetime "email_sent_at"
    t.datetime "read_at"
    t.boolean  "is_processed",    default: false
    t.string   "frequency"
    t.boolean  "send_email",      default: true
    t.integer  "invitation_id",   index: {name: "index_notifications_on_invitation_id"}
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false, index: {name: "index_oauth_access_grants_on_token", unique: true}
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", index: {name: "index_oauth_access_tokens_on_resource_owner_id"}
    t.integer  "application_id"
    t.text     "token",             null: false, index: {name: "index_oauth_access_tokens_on_token", unique: true}
    t.string   "refresh_token",     index: {name: "index_oauth_access_tokens_on_refresh_token", unique: true}
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         null: false
    t.string   "uid",          null: false, index: {name: "index_oauth_applications_on_uid", unique: true}
    t.string   "secret",       null: false
    t.text     "redirect_uri", null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: :cascade do |t|
    t.string   "title"
    t.boolean  "is_public"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people_orders", force: :cascade do |t|
    t.string   "name"
    t.string   "order",      default: [],              array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.string   "title"
    t.integer  "user_id",         null: false, index: {name: "index_questions_on_user_id"}
    t.text     "body"
    t.boolean  "share_public",    default: true,  null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.boolean  "share_following", default: false
  end

  create_table "read_marks", force: :cascade do |t|
    t.integer  "readable_id"
    t.string   "readable_type", null: false
    t.integer  "reader_id",     index: {name: "read_marks_reader_readable_index", with: ["reader_type", "readable_type", "readable_id"]}
    t.string   "reader_type",   null: false
    t.datetime "timestamp"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",          index: {name: "index_roles_on_name"}
    t.integer  "resource_id",   index: {name: "index_roles_on_resource_id"}
    t.string   "resource_type", index: {name: "index_roles_on_resource_type"}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "roles", ["id"], name: "index_roles_on_id", unique: true
  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"

  create_table "settings", force: :cascade do |t|
    t.string   "var",         null: false
    t.text     "value"
    t.integer  "target_id",   null: false
    t.string   "target_type", null: false, index: {name: "index_settings_on_target_type_and_target_id_and_var", with: ["target_id", "var"], unique: true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "share_settings", force: :cascade do |t|
    t.integer  "user_id",               index: {name: "index_share_settings_on_user_id"}
    t.string   "shareable_object_type", index: {name: "index_share_settings_on_shareable_object", with: ["shareable_object_id"]}
    t.integer  "shareable_object_id"
    t.string   "sharing_object_type",   index: {name: "index_share_settings_on_sharing_object", with: ["sharing_object_id"]}
    t.integer  "sharing_object_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "source"
  end

  create_table "slack_channels", force: :cascade do |t|
    t.string   "name"
    t.string   "slack_channel_id"
    t.integer  "slack_team_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "slack_members", force: :cascade do |t|
    t.string   "name"
    t.string   "slack_member_id"
    t.integer  "slack_team_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "gravatar_url"
    t.integer  "user_id"
  end

  create_table "slack_teams", force: :cascade do |t|
    t.string   "team_id",          null: false
    t.integer  "domain_id",        null: false
    t.string   "team_name"
    t.string   "scope"
    t.string   "access_token"
    t.text     "incoming_webhook"
    t.text     "bot"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "user_ids",         default: [],              array: true
  end

  create_table "slack_tip_drafts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.boolean  "is_draft"
    t.integer  "slack_member_id", index: {name: "index_slack_tip_drafts_on_slack_member_id"}
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "tip_id"
  end

  create_table "slack_topic_connections", force: :cascade do |t|
    t.integer  "slack_team_id"
    t.integer  "slack_channel_id"
    t.string   "topic_id"
    t.integer  "domain_id"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "spam_records", force: :cascade do |t|
    t.string   "to"
    t.string   "from"
    t.string   "subject"
    t.text     "html"
    t.string   "spam_score"
    t.text     "spam_report"
    t.string   "envelope"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string   "name"
    t.float    "amount"
    t.string   "interval"
    t.string   "stripe_plan_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "stripe_subscription_id"
    t.datetime "start_date"
    t.string   "tenure"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "domain_id"
  end

  create_table "tip_assignments", force: :cascade do |t|
    t.integer  "assignment_id"
    t.integer  "tip_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "assignment_type"
  end

  create_table "tip_links", force: :cascade do |t|
    t.string   "url"
    t.integer  "tip_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "description"
    t.string   "avatar"
    t.string   "avatar_tmp"
    t.boolean  "avatar_processing"
    t.boolean  "processed",         default: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "tips", force: :cascade do |t|
    t.integer  "user_id",                             null: false, index: {name: "index_tips_on_user_id"}
    t.string   "title",                               index: {name: "index_tips_on_title", case_sensitive: false}
    t.text     "body"
    t.integer  "color_index"
    t.string   "access_key",                          index: {name: "index_tips_on_access_key"}
    t.boolean  "share_public",                        default: true,  null: false
    t.boolean  "share_following",                     default: false, null: false
    t.hstore   "properties"
    t.hstore   "statistics"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.datetime "expiration_date"
    t.boolean  "is_disabled",                         default: false
    t.integer  "cached_scoped_like_votes_total",      default: 0, index: {name: "index_tips_on_cached_scoped_like_votes_total"}
    t.integer  "cached_scoped_like_votes_score",      default: 0, index: {name: "index_tips_on_cached_scoped_like_votes_score"}
    t.integer  "cached_scoped_like_votes_up",         default: 0, index: {name: "index_tips_on_cached_scoped_like_votes_up"}
    t.integer  "cached_scoped_like_votes_down",       default: 0, index: {name: "index_tips_on_cached_scoped_like_votes_down"}
    t.integer  "cached_scoped_like_weighted_score",   default: 0, index: {name: "index_tips_on_cached_scoped_like_weighted_score"}
    t.integer  "cached_scoped_like_weighted_total",   default: 0, index: {name: "index_tips_on_cached_scoped_like_weighted_total"}
    t.float    "cached_scoped_like_weighted_average", default: 0.0, index: {name: "index_tips_on_cached_scoped_like_weighted_average"}
    t.jsonb    "attachments_json",                    default: {},    null: false, index: {name: "index_tips_on_attachments_json", using: :gin}
    t.datetime "start_date"
    t.datetime "due_date"
    t.datetime "completion_date"
    t.integer  "completed_percentage",                default: 0
    t.integer  "work_estimation"
    t.decimal  "resource_required"
    t.datetime "expected_completion_date"
    t.boolean  "is_deleted",                          default: false
    t.string   "priority_level"
    t.integer  "value"
    t.integer  "effort"
    t.integer  "actual_work"
    t.integer  "confidence_range"
    t.decimal  "resource_expended"
    t.boolean  "is_secret",                           default: false
  end

  create_table "tips_dependencies", force: :cascade do |t|
    t.integer "depended_on_by"
    t.integer "depends_on"
  end

  create_table "topic_orders", force: :cascade do |t|
    t.string   "subtopic_order", default: [],                 array: true
    t.string   "tip_order",      default: [],                 array: true
    t.integer  "topic_id",       null: false, index: {name: "index_topic_orders_on_topic_id"}
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "name"
    t.boolean  "is_default",     default: false
  end

  create_table "topic_orders_tips", id: false, force: :cascade do |t|
    t.integer "topic_order_id", index: {name: "index_topic_orders_tips_on_topic_order_id"}
    t.integer "tip_id",         index: {name: "index_topic_orders_tips_on_tip_id"}
  end

  create_table "topic_orders_topics", id: false, force: :cascade do |t|
    t.integer "topic_order_id", index: {name: "index_topic_orders_topics_on_topic_order_id"}
    t.integer "topic_id",       index: {name: "index_topic_orders_topics_on_topic_id"}
  end

  create_table "topic_orders_users", id: false, force: :cascade do |t|
    t.integer "user_id",        null: false, index: {name: "index_topic_orders_users_on_user_id_and_topic_order_id", with: ["topic_order_id"]}
    t.integer "topic_order_id", null: false, index: {name: "index_topic_orders_users_on_topic_order_id_and_user_id", with: ["user_id"]}
  end

  create_table "topic_preferences", force: :cascade do |t|
    t.integer  "topic_id",                    null: false, index: {name: "index_topic_preferences_on_topic_id"}
    t.integer  "user_id",                     null: false, index: {name: "index_topic_preferences_on_user_id"}
    t.integer  "background_color_index",      default: 1,     null: false
    t.string   "background_image",            default: "",    null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "background_image_tmp"
    t.boolean  "background_image_processing"
    t.boolean  "share_public",                default: true
    t.boolean  "share_following",             default: false
    t.integer  "follow_scope",                default: 2
    t.text     "link_option"
    t.string   "link_password"
  end
  add_index "topic_preferences", ["topic_id", "user_id"], name: "index_topic_preferences_on_topic_id_and_user_id"

  create_table "topic_users", force: :cascade do |t|
    t.integer  "follower_id", null: false
    t.integer  "user_id",     null: false
    t.integer  "topic_id",    null: false
    t.integer  "status",      default: 0, null: false, index: {name: "index_topic_users_on_status_and_follower_id_and_topic_id", with: ["follower_id", "topic_id"]}
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "topics", force: :cascade do |t|
    t.string   "title",                     null: false, index: {name: "index_topics_on_title_and_ancestry", with: ["ancestry"], unique: true, case_sensitive: false}
    t.text     "description"
    t.integer  "user_id",                   null: false, index: {name: "index_topics_on_user_id"}
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "ancestry",                  index: {name: "index_topics_on_ancestry"}
    t.integer  "old_subtopic_id"
    t.string   "default_view_id"
    t.string   "image"
    t.boolean  "is_deleted",                default: false
    t.boolean  "is_disabled",               default: false
    t.integer  "label_order_id",            index: {name: "index_topics_on_label_order_id"}
    t.integer  "people_order_id",           index: {name: "index_topics_on_people_order_id"}
    t.boolean  "show_tips_on_parent_topic", default: true
    t.boolean  "cards_hidden"
    t.boolean  "is_secret",                 default: false
    t.boolean  "apply_to_all_childrens",    default: false
  end

  create_table "user_profiles", force: :cascade do |t|
    t.integer  "user_id",                     index: {name: "index_user_profiles_on_user_id"}
    t.string   "avatar"
    t.string   "avatar_tmp"
    t.boolean  "avatar_processing"
    t.string   "background_image"
    t.boolean  "background_image_processing"
    t.string   "background_image_tmp"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "color_index",                 default: 3
    t.datetime "daily_sent_at"
    t.datetime "weekly_sent_at"
    t.text     "description"
    t.boolean  "follow_all_members",          default: true
    t.boolean  "follow_all_hives",            default: true
    t.integer  "resource_capacity"
  end

  create_table "user_topic_label_orders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "topic_id"
    t.integer "label_order_id"
  end

  create_table "user_topic_people_orders", force: :cascade do |t|
    t.integer "user_id"
    t.integer "topic_id"
    t.integer "people_order_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false, index: {name: "index_users_on_email", unique: true, case_sensitive: false}
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token",   index: {name: "index_users_on_reset_password_token", unique: true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token",     index: {name: "index_users_on_confirmation_token", unique: true}
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token",           index: {name: "index_users_on_unlock_token", unique: true}
    t.datetime "locked_at"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "username",               null: false, index: {name: "index_users_on_username", unique: true, case_sensitive: false}
    t.integer  "order_id",               index: {name: "index_users_on_order_id"}
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", index: {name: "index_users_roles_on_user_id_and_role_id", with: ["role_id"]}
    t.integer "role_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false, index: {name: "index_versions_on_item_type_and_item_id", with: ["item_id"]}
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  create_table "view_assignments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "view_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "domain_id"
  end

  create_table "views", force: :cascade do |t|
    t.integer  "user_id",          default: 0,    null: false, index: {name: "index_views_on_user_id"}
    t.string   "kind"
    t.string   "name"
    t.jsonb    "settings"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.boolean  "show_nested_tips", default: true, null: false
  end

  create_table "votes", force: :cascade do |t|
    t.integer  "votable_id",   index: {name: "index_votes_on_votable_id_and_votable_type_and_vote_scope", with: ["votable_type", "vote_scope"]}
    t.string   "votable_type"
    t.integer  "voter_id",     index: {name: "index_votes_on_voter_id_and_voter_type_and_vote_scope", with: ["voter_type", "vote_scope"]}
    t.string   "voter_type"
    t.boolean  "vote_flag"
    t.string   "vote_scope"
    t.integer  "vote_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "notifications", "invitations"
  add_foreign_key "slack_tip_drafts", "slack_members"
  add_foreign_key "topic_preferences", "topics"
  add_foreign_key "topics", "label_orders"
  add_foreign_key "topics", "people_orders"
  add_foreign_key "users", "orders"
end
