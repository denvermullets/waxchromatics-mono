class AddMusicbrainzAndCoverArtToReleaseGroupsAndReleases < ActiveRecord::Migration[8.0]
  def change
    add_column :release_groups, :musicbrainz_id, :string
    add_column :release_groups, :cover_art_url, :string

    add_column :releases, :musicbrainz_id, :string
    add_column :releases, :cover_art_url, :string

    add_index :release_groups, :musicbrainz_id, unique: true
    add_index :releases, :musicbrainz_id, unique: true
  end
end
