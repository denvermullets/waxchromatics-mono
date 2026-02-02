class CreateReleaseArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :release_artists do |t|
      t.references :release, null: false, foreign_key: true
      t.references :artist, null: false, foreign_key: true
      t.string :role
      t.string :anv
      t.integer :position
      t.string :join_string

      t.timestamps
    end
    add_index :release_artists, [ :release_id, :artist_id ]
  end
end
