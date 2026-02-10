class CreateReleaseGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :release_genres do |t|
      t.references :release, null: false, foreign_key: true
      t.string :genre, null: false

      t.timestamps
    end

    add_index :release_genres, [:release_id, :genre], unique: true
  end
end
