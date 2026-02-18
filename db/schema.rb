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

ActiveRecord::Schema[8.1].define(version: 2026_02_17_124740) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "discography_ingested", default: false, null: false
    t.integer "discogs_id"
    t.string "name", null: false
    t.text "profile"
    t.string "real_name"
    t.datetime "updated_at", null: false
    t.index ["discogs_id"], name: "index_artists_on_discogs_id", unique: true
  end

  create_table "collection_import_rows", force: :cascade do |t|
    t.string "artist_name"
    t.string "catalog_number"
    t.bigint "collection_import_id", null: false
    t.datetime "created_at", null: false
    t.integer "discogs_release_id"
    t.text "error_message"
    t.string "label_name"
    t.string "media_condition"
    t.jsonb "raw_data"
    t.bigint "release_id"
    t.string "status", default: "pending", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["collection_import_id"], name: "index_collection_import_rows_on_collection_import_id"
    t.index ["release_id"], name: "index_collection_import_rows_on_release_id"
    t.index ["status"], name: "index_collection_import_rows_on_status"
  end

  create_table "collection_imports", force: :cascade do |t|
    t.integer "completed_rows", default: 0
    t.datetime "created_at", null: false
    t.integer "failed_rows", default: 0
    t.string "file_path"
    t.string "filename"
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_collection_imports_on_user_id"
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.string "condition", default: "NM", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.date "purchase_date"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.bigint "release_id", null: false
    t.date "sale_date"
    t.decimal "sale_price", precision: 10, scale: 2
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["collection_id", "release_id"], name: "index_collection_items_on_collection_id_and_release_id"
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
    t.index ["release_id"], name: "index_collection_items_on_release_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "labels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discogs_id"
    t.string "name", null: false
    t.bigint "parent_label_id"
    t.text "profile"
    t.datetime "updated_at", null: false
    t.index ["discogs_id"], name: "index_labels_on_discogs_id", unique: true
    t.index ["parent_label_id"], name: "index_labels_on_parent_label_id"
  end

  create_table "pending_ingests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discogs_id", null: false
    t.json "metadata"
    t.string "resource_type", default: "Artist", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["discogs_id", "resource_type"], name: "index_pending_ingests_on_discogs_id_and_resource_type", unique: true
  end

  create_table "ratings", force: :cascade do |t|
    t.text "comments"
    t.integer "communication_rating", null: false
    t.string "condition_accuracy", null: false
    t.datetime "created_at", null: false
    t.integer "overall_rating", null: false
    t.integer "packing_shipping_rating", null: false
    t.bigint "rateable_id", null: false
    t.string "rateable_type", null: false
    t.bigint "reviewed_user_id", null: false
    t.bigint "reviewer_id", null: false
    t.text "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["rateable_type", "rateable_id", "reviewer_id"], name: "index_ratings_unique_per_reviewer", unique: true
    t.index ["rateable_type", "rateable_id"], name: "index_ratings_on_rateable_type_and_rateable_id"
    t.index ["reviewed_user_id"], name: "index_ratings_on_reviewed_user_id"
    t.index ["reviewer_id"], name: "index_ratings_on_reviewer_id"
  end

  create_table "release_contributors", force: :cascade do |t|
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "release_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_release_contributors_on_artist_id"
    t.index ["release_id", "artist_id"], name: "index_release_contributors_on_release_id_and_artist_id"
    t.index ["release_id"], name: "index_release_contributors_on_release_id"
  end

  create_table "release_formats", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.text "descriptions"
    t.string "name"
    t.integer "quantity"
    t.bigint "release_id", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id"], name: "index_release_formats_on_release_id"
  end

  create_table "release_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "genre", null: false
    t.bigint "release_id", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id", "genre"], name: "index_release_genres_on_release_id_and_genre", unique: true
    t.index ["release_id"], name: "index_release_genres_on_release_id"
  end

  create_table "release_groups", force: :cascade do |t|
    t.string "cover_art_url"
    t.datetime "created_at", null: false
    t.integer "discogs_id"
    t.bigint "main_release_id"
    t.string "musicbrainz_id"
    t.string "release_type", default: "Album", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["discogs_id"], name: "index_release_groups_on_discogs_id", unique: true
    t.index ["musicbrainz_id"], name: "index_release_groups_on_musicbrainz_id", unique: true
    t.index ["release_type"], name: "index_release_groups_on_release_type"
  end

  create_table "release_identifiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "discogs_id"
    t.string "identifier_type"
    t.bigint "release_id", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["discogs_id"], name: "index_release_identifiers_on_discogs_id", unique: true
    t.index ["release_id", "identifier_type"], name: "index_release_identifiers_on_release_id_and_identifier_type"
    t.index ["release_id"], name: "index_release_identifiers_on_release_id"
  end

  create_table "release_labels", force: :cascade do |t|
    t.string "catalog_number"
    t.datetime "created_at", null: false
    t.bigint "label_id"
    t.bigint "release_id", null: false
    t.datetime "updated_at", null: false
    t.index ["label_id"], name: "index_release_labels_on_label_id"
    t.index ["release_id", "label_id"], name: "index_release_labels_on_release_id_and_label_id"
    t.index ["release_id"], name: "index_release_labels_on_release_id"
  end

  create_table "release_styles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "release_id", null: false
    t.string "style", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id", "style"], name: "index_release_styles_on_release_id_and_style", unique: true
    t.index ["release_id"], name: "index_release_styles_on_release_id"
  end

  create_table "releases", force: :cascade do |t|
    t.bigint "artist_id"
    t.string "country"
    t.string "cover_art_url"
    t.datetime "created_at", null: false
    t.integer "discogs_id"
    t.string "musicbrainz_id"
    t.text "notes"
    t.bigint "release_group_id"
    t.string "released"
    t.string "status"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_releases_on_artist_id"
    t.index ["discogs_id"], name: "index_releases_on_discogs_id", unique: true
    t.index ["musicbrainz_id"], name: "index_releases_on_musicbrainz_id", unique: true
    t.index ["release_group_id"], name: "index_releases_on_release_group_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "duration"
    t.string "position"
    t.bigint "release_id", null: false
    t.integer "sequence", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["release_id", "sequence"], name: "index_tracks_on_release_id_and_sequence"
    t.index ["release_id"], name: "index_tracks_on_release_id"
  end

  create_table "trade_items", force: :cascade do |t|
    t.bigint "collection_item_id", null: false
    t.datetime "created_at", null: false
    t.bigint "release_id", null: false
    t.bigint "trade_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["collection_item_id"], name: "index_trade_items_on_collection_item_id"
    t.index ["release_id"], name: "index_trade_items_on_release_id"
    t.index ["trade_id", "collection_item_id"], name: "index_trade_items_on_trade_id_and_collection_item_id", unique: true
    t.index ["trade_id"], name: "index_trade_items_on_trade_id"
    t.index ["user_id"], name: "index_trade_items_on_user_id"
  end

  create_table "trade_list_items", force: :cascade do |t|
    t.bigint "collection_item_id", null: false
    t.string "condition", default: "NM", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "release_id", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["collection_item_id"], name: "index_trade_list_items_on_collection_item_id"
    t.index ["release_id"], name: "index_trade_list_items_on_release_id"
    t.index ["user_id", "release_id"], name: "index_trade_list_items_on_user_id_and_release_id"
    t.index ["user_id"], name: "index_trade_list_items_on_user_id"
  end

  create_table "trade_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "trade_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["trade_id", "created_at"], name: "index_trade_messages_on_trade_id_and_created_at"
    t.index ["trade_id"], name: "index_trade_messages_on_trade_id"
    t.index ["user_id"], name: "index_trade_messages_on_user_id"
  end

  create_table "trade_shipments", force: :cascade do |t|
    t.string "carrier"
    t.datetime "created_at", null: false
    t.datetime "last_event_at"
    t.text "last_event_description"
    t.string "status", default: "pending", null: false
    t.string "tracking_number"
    t.bigint "trade_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["trade_id", "user_id"], name: "index_trade_shipments_on_trade_id_and_user_id", unique: true
    t.index ["trade_id"], name: "index_trade_shipments_on_trade_id"
    t.index ["user_id"], name: "index_trade_shipments_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.bigint "initiator_id", null: false
    t.datetime "proposed_at"
    t.bigint "proposed_by_id"
    t.bigint "recipient_id", null: false
    t.datetime "responded_at"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id", "status"], name: "index_trades_on_initiator_id_and_status"
    t.index ["initiator_id"], name: "index_trades_on_initiator_id"
    t.index ["proposed_by_id"], name: "index_trades_on_proposed_by_id"
    t.index ["recipient_id", "status"], name: "index_trades_on_recipient_id_and_status"
    t.index ["recipient_id"], name: "index_trades_on_recipient_id"
    t.index ["status"], name: "index_trades_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "default_collection_view", default: "grid", null: false
    t.string "email_address", null: false
    t.string "location"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "collection_import_id"
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.bigint "release_id"
    t.string "whodunnit"
    t.index ["collection_import_id"], name: "index_versions_on_collection_import_id"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit", "item_type", "created_at"], name: "index_versions_on_whodunnit_item_type_created_at"
  end

  create_table "wantlist_items", force: :cascade do |t|
    t.string "condition", default: "NM", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "release_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["release_id"], name: "index_wantlist_items_on_release_id"
    t.index ["user_id", "release_id"], name: "index_wantlist_items_on_user_id_and_release_id"
    t.index ["user_id"], name: "index_wantlist_items_on_user_id"
  end

  add_foreign_key "collection_import_rows", "collection_imports"
  add_foreign_key "collection_import_rows", "releases"
  add_foreign_key "collection_imports", "users"
  add_foreign_key "collection_items", "collections"
  add_foreign_key "collection_items", "releases"
  add_foreign_key "collections", "users"
  add_foreign_key "labels", "labels", column: "parent_label_id"
  add_foreign_key "ratings", "users", column: "reviewed_user_id"
  add_foreign_key "ratings", "users", column: "reviewer_id"
  add_foreign_key "release_contributors", "artists"
  add_foreign_key "release_contributors", "releases"
  add_foreign_key "release_formats", "releases"
  add_foreign_key "release_genres", "releases"
  add_foreign_key "release_identifiers", "releases"
  add_foreign_key "release_labels", "labels"
  add_foreign_key "release_labels", "releases"
  add_foreign_key "release_styles", "releases"
  add_foreign_key "releases", "artists"
  add_foreign_key "releases", "release_groups"
  add_foreign_key "sessions", "users"
  add_foreign_key "tracks", "releases"
  add_foreign_key "trade_items", "collection_items"
  add_foreign_key "trade_items", "releases"
  add_foreign_key "trade_items", "trades"
  add_foreign_key "trade_items", "users"
  add_foreign_key "trade_list_items", "collection_items"
  add_foreign_key "trade_list_items", "releases"
  add_foreign_key "trade_list_items", "users"
  add_foreign_key "trade_messages", "trades"
  add_foreign_key "trade_messages", "users"
  add_foreign_key "trade_shipments", "trades"
  add_foreign_key "trade_shipments", "users"
  add_foreign_key "trades", "users", column: "initiator_id"
  add_foreign_key "trades", "users", column: "proposed_by_id"
  add_foreign_key "trades", "users", column: "recipient_id"
  add_foreign_key "wantlist_items", "releases"
  add_foreign_key "wantlist_items", "users"
end
