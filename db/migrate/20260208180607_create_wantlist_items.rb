class CreateWantlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :wantlist_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end

    add_index :wantlist_items, [:user_id, :release_id], unique: true
  end
end
