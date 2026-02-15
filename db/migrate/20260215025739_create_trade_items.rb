class CreateTradeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_items do |t|
      t.references :trade, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true
      t.references :collection_item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :trade_items, [:trade_id, :collection_item_id], unique: true
  end
end
