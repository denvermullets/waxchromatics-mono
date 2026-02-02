class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.references :release, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :position
      t.string :title
      t.string :duration

      t.timestamps
    end
    add_index :tracks, [ :release_id, :sequence ]
  end
end
