class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.integer :discogs_id
      t.string :name, null: false
      t.string :real_name
      t.text :profile

      t.timestamps
    end
    add_index :artists, :discogs_id, unique: true
  end
end
