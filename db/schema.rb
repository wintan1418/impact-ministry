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

ActiveRecord::Schema[8.1].define(version: 2026_05_29_102103) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "devotional_deliveries", force: :cascade do |t|
    t.datetime "clicked_at"
    t.datetime "created_at", null: false
    t.bigint "devotional_id", null: false
    t.bigint "email_subscriber_id", null: false
    t.datetime "opened_at"
    t.string "postmark_message_id"
    t.datetime "sent_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clicked_at"], name: "index_devotional_deliveries_on_clicked_at"
    t.index ["devotional_id", "email_subscriber_id"], name: "index_devotional_deliveries_on_devotional_and_subscriber", unique: true
    t.index ["devotional_id"], name: "index_devotional_deliveries_on_devotional_id"
    t.index ["email_subscriber_id"], name: "index_devotional_deliveries_on_email_subscriber_id"
    t.index ["opened_at"], name: "index_devotional_deliveries_on_opened_at"
    t.index ["postmark_message_id"], name: "index_devotional_deliveries_on_postmark_message_id", unique: true, where: "(postmark_message_id IS NOT NULL)"
    t.index ["sent_at"], name: "index_devotional_deliveries_on_sent_at"
  end

  create_table "devotional_highlights", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "devotional_id", null: false
    t.text "note"
    t.datetime "saved_at", null: false
    t.text "text_range", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["devotional_id"], name: "index_devotional_highlights_on_devotional_id"
    t.index ["user_id", "saved_at"], name: "index_devotional_highlights_on_user_id_and_saved_at"
    t.index ["user_id"], name: "index_devotional_highlights_on_user_id"
  end

  create_table "devotionals", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.datetime "published_at"
    t.date "scheduled_for", null: false
    t.string "scripture_reference", null: false
    t.string "slug", null: false
    t.string "tags", default: [], array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_devotionals_on_author_id"
    t.index ["published_at"], name: "index_devotionals_on_published_at"
    t.index ["scheduled_for"], name: "index_devotionals_on_scheduled_for", unique: true
    t.index ["slug"], name: "index_devotionals_on_slug", unique: true
    t.index ["tags"], name: "index_devotionals_on_tags", using: :gin
    t.index ["title"], name: "index_devotionals_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "donations", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.string "designation", default: "general", null: false
    t.datetime "donated_at"
    t.bigint "donor_id", null: false
    t.string "frequency", default: "once", null: false
    t.datetime "receipt_sent_at"
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.index ["designation"], name: "index_donations_on_designation"
    t.index ["donated_at"], name: "index_donations_on_donated_at"
    t.index ["donor_id"], name: "index_donations_on_donor_id"
    t.index ["status"], name: "index_donations_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_donations_on_stripe_checkout_session_id", unique: true, where: "(stripe_checkout_session_id IS NOT NULL)"
    t.index ["stripe_payment_intent_id"], name: "index_donations_on_stripe_payment_intent_id", unique: true, where: "(stripe_payment_intent_id IS NOT NULL)"
    t.index ["stripe_subscription_id"], name: "index_donations_on_stripe_subscription_id"
  end

  create_table "donors", force: :cascade do |t|
    t.jsonb "address", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", default: "", null: false
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email"], name: "index_donors_on_email"
    t.index ["stripe_customer_id"], name: "index_donors_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["user_id"], name: "index_donors_on_user_id"
  end

  create_table "email_subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.jsonb "preferences", default: {}, null: false
    t.string "source", default: "manual", null: false
    t.datetime "subscribed_at"
    t.string "token", null: false
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_email_subscribers_on_lower_email", unique: true
    t.index ["token"], name: "index_email_subscribers_on_token", unique: true
    t.index ["unsubscribed_at"], name: "index_email_subscribers_on_unsubscribed_at"
  end

  create_table "event_rsvps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.integer "party_size", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "email"], name: "index_event_rsvps_on_event_id_and_email", unique: true
    t.index ["event_id"], name: "index_event_rsvps_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "capacity"
    t.string "cover_photo_slug"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "location"
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "virtual_link"
    t.index ["published", "starts_at"], name: "index_events_on_published_and_starts_at"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["starts_at"], name: "index_events_on_starts_at"
  end

  create_table "feedback_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "kind", default: "general", null: false
    t.string "name", null: false
    t.boolean "replied", default: false, null: false
    t.datetime "replied_at"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_feedback_messages_on_created_at", order: :desc
    t.index ["kind"], name: "index_feedback_messages_on_kind"
    t.index ["replied"], name: "index_feedback_messages_on_replied"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "published", default: true, null: false
    t.jsonb "seo_meta", default: {}, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "partnerships", force: :cascade do |t|
    t.string "contact_email", null: false
    t.string "contact_name", null: false
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "interest_areas", default: [], array: true
    t.text "message", null: false
    t.string "organization_name", null: false
    t.string "organization_type", default: "other", null: false
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_partnerships_on_created_at", order: :desc
    t.index ["organization_type"], name: "index_partnerships_on_organization_type"
    t.index ["status"], name: "index_partnerships_on_status"
  end

  create_table "podcast_episodes", force: :cascade do |t|
    t.string "audio_url"
    t.string "cover_photo_slug"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_seconds"
    t.integer "episode_number", null: false
    t.string "guest_names", default: [], array: true
    t.datetime "published_at"
    t.date "scheduled_for"
    t.integer "season", default: 1, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "transcript"
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index ["published_at"], name: "index_podcast_episodes_on_published_at"
    t.index ["season", "episode_number"], name: "index_podcast_episodes_on_season_and_episode_number", unique: true
    t.index ["slug"], name: "index_podcast_episodes_on_slug", unique: true
  end

  create_table "prayer_requests", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "is_anonymous", default: false, null: false
    t.boolean "is_public", default: false, null: false
    t.string "name"
    t.integer "prayed_count", default: 0, null: false
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prayer_requests_on_created_at"
    t.index ["status", "is_public", "created_at"], name: "index_prayer_requests_on_status_public_created", order: { created_at: :desc }
    t.index ["status"], name: "index_prayer_requests_on_status"
  end

  create_table "processed_stripe_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "processed_at", null: false
    t.string "stripe_event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_processed_stripe_events_on_event_type"
    t.index ["stripe_event_id"], name: "index_processed_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.string "category", default: "guide", null: false
    t.string "cover_photo_slug"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "downloads_count", default: 0, null: false
    t.boolean "featured", default: false, null: false
    t.datetime "published_at"
    t.boolean "requires_email", default: true, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "published_at"], name: "index_resources_on_category_and_published_at", order: { published_at: :desc }
    t.index ["featured"], name: "index_resources_on_featured"
    t.index ["published_at"], name: "index_resources_on_published_at"
    t.index ["slug"], name: "index_resources_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "kind", default: "string", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "testimonies", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.datetime "approved_at"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "featured", default: false, null: false
    t.string "location"
    t.string "name"
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["approved", "featured", "submitted_at"], name: "index_testimonies_on_approved_featured_submitted", order: { submitted_at: :desc }
    t.index ["approved"], name: "index_testimonies_on_approved"
    t.index ["submitted_at"], name: "index_testimonies_on_submitted_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.string "email_address", null: false
    t.date "last_read_on"
    t.integer "longest_streak", default: 0, null: false
    t.string "name"
    t.string "password_digest", null: false
    t.string "role", default: "subscriber", null: false
    t.datetime "updated_at", null: false
    t.index ["current_streak"], name: "index_users_on_current_streak"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "devotional_deliveries", "devotionals"
  add_foreign_key "devotional_deliveries", "email_subscribers"
  add_foreign_key "devotional_highlights", "devotionals"
  add_foreign_key "devotional_highlights", "users"
  add_foreign_key "devotionals", "users", column: "author_id"
  add_foreign_key "donations", "donors"
  add_foreign_key "donors", "users"
  add_foreign_key "event_rsvps", "events"
  add_foreign_key "sessions", "users"
end
