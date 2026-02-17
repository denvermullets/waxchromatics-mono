class RemoveNotesFromTrades < ActiveRecord::Migration[8.1]
  def change
    remove_column :trades, :notes, :text
  end
end
