class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :initiator, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.datetime :proposed_at
      t.datetime :responded_at

      t.timestamps
    end

    add_index :trades, :status
    add_index :trades, [:initiator_id, :status]
    add_index :trades, [:recipient_id, :status]
  end
end
