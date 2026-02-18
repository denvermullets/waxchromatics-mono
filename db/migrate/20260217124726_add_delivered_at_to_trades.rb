class AddDeliveredAtToTrades < ActiveRecord::Migration[8.1]
  def change
    add_column :trades, :delivered_at, :datetime
  end
end
