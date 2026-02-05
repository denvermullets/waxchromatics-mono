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

ActiveRecord::Schema[8.1].define(version: 2026_02_05_104542) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discogs_id"
    t.string "name", null: false
    t.text "profile"
    t.string "real_name"
    t.datetime "updated_at", null: false
    t.index ["discogs_id"], name: "index_artists_on_discogs_id", unique: true
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.string "condition"
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

  create_table "release_artists", force: :cascade do |t|
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "release_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_release_artists_on_artist_id"
    t.index ["release_id", "artist_id"], name: "index_release_artists_on_release_id_and_artist_id"
    t.index ["release_id"], name: "index_release_artists_on_release_id"
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

  create_table "release_groups", force: :cascade do |t|
    t.string "cover_art_url"
    t.datetime "created_at", null: false
    t.integer "discogs_id"
    t.bigint "main_release_id"
    t.string "musicbrainz_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["discogs_id"], name: "index_release_groups_on_discogs_id", unique: true
    t.index ["musicbrainz_id"], name: "index_release_groups_on_musicbrainz_id", unique: true
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

  create_table "releases", force: :cascade do |t|
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

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "collection_items", "collections"
  add_foreign_key "collection_items", "releases"
  add_foreign_key "collections", "users"
  add_foreign_key "labels", "labels", column: "parent_label_id"
  add_foreign_key "release_artists", "artists"
  add_foreign_key "release_artists", "releases"
  add_foreign_key "release_formats", "releases"
  add_foreign_key "release_identifiers", "releases"
  add_foreign_key "release_labels", "labels"
  add_foreign_key "release_labels", "releases"
  add_foreign_key "releases", "release_groups"
  add_foreign_key "sessions", "users"
  add_foreign_key "tracks", "releases"
end
