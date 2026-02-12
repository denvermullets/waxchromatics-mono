class CreateCollectionImports < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :filename
      t.string :file_path
      t.integer :total_rows, default: 0
      t.integer :completed_rows, default: 0
      t.integer :failed_rows, default: 0

      t.timestamps
    end

    create_table :collection_import_rows do |t|
      t.references :collection_import, null: false, foreign_key: true
      t.integer :discogs_release_id
      t.string :artist_name
      t.string :title
      t.string :catalog_number
      t.string :label_name
      t.string :media_condition
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.references :release, foreign_key: true
      t.jsonb :raw_data

      t.timestamps
    end

    add_index :collection_import_rows, :status
  end
end
