class CreateReleaseGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :release_groups do |t|
      t.integer :discogs_id
      t.string :title, null: false
      t.integer :year
      t.bigint :main_release_id

      t.timestamps
    end
    add_index :release_groups, :discogs_id, unique: true
  end
end
