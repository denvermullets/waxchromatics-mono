class CreateMasters < ActiveRecord::Migration[8.1]
  def change
    create_table :masters do |t|
      t.integer :discogs_id
      t.string :title, null: false
      t.integer :year
      t.bigint :main_release_id

      t.timestamps
    end
    add_index :masters, :discogs_id, unique: true
  end
end
