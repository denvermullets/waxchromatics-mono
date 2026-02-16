class AddProposedByToTrades < ActiveRecord::Migration[8.1]
  def change
    add_reference :trades, :proposed_by, null: true, foreign_key: { to_table: :users }
  end
end
