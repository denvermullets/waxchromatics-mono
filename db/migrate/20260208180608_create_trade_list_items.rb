class CreateTradeListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_list_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true
      t.references :collection_item, null: false, foreign_key: true
      t.text :notes
      t.string :status, default: "available", null: false

      t.timestamps
    end

    add_index :trade_list_items, [:user_id, :release_id], unique: true
  end
end
