class CreateLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :labels do |t|
      t.integer :discogs_id
      t.string :name, null: false
      t.text :profile
      t.references :parent_label, foreign_key: { to_table: :labels }

      t.timestamps
    end
    add_index :labels, :discogs_id, unique: true
  end
end
