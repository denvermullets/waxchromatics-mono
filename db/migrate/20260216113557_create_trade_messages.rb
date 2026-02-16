class CreateTradeMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_messages do |t|
      t.references :trade, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :trade_messages, [:trade_id, :created_at]
  end
end
