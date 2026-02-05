class CreateReleaseIdentifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :release_identifiers do |t|
      t.references :release, null: false, foreign_key: true
      t.integer :discogs_id
      t.string :identifier_type
      t.string :value
      t.string :description

      t.timestamps
    end

    add_index :release_identifiers, :discogs_id, unique: true
    add_index :release_identifiers, [:release_id, :identifier_type]
  end
end
