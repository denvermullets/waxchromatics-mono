class RestructureReleaseArtists < ActiveRecord::Migration[8.1]
  def change
    add_reference :releases, :artist, null: true, foreign_key: true
    rename_table :release_artists, :release_contributors
  end
end
