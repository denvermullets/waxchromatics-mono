class CreateConnectionCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :connection_caches do |t|
      t.references :artist_a, null: false, foreign_key: { to_table: :artists, on_delete: :cascade }
      t.references :artist_b, null: false, foreign_key: { to_table: :artists, on_delete: :cascade }
      t.boolean :found, null: false, default: false
      t.integer :degrees
      t.jsonb :path_data, null: false, default: []

      t.timestamps
    end

    add_index :connection_caches, [:artist_a_id, :artist_b_id], unique: true
  end
end
