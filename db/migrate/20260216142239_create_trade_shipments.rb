class CreateTradeShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_shipments do |t|
      t.references :trade, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :carrier
      t.string :tracking_number
      t.string :status, null: false, default: "pending"
      t.text :last_event_description
      t.datetime :last_event_at

      t.timestamps
    end

    add_index :trade_shipments, [:trade_id, :user_id], unique: true
  end
end
