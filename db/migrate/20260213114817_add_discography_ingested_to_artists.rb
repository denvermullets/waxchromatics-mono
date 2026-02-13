class AddDiscographyIngestedToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :discography_ingested, :boolean, default: false, null: false
  end
end
