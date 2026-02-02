class CreateReleases < ActiveRecord::Migration[8.1]
  def change
    create_table :releases do |t|
      t.integer :discogs_id
      t.string :title, null: false
      t.string :released
      t.string :country
      t.text :notes
      t.string :status
      t.references :master, foreign_key: true

      t.timestamps
    end
    add_index :releases, :discogs_id, unique: true
  end
end
