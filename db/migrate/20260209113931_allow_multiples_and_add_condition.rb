class AllowMultiplesAndAddCondition < ActiveRecord::Migration[8.1]
  def change
    # Add condition to wantlist_items and trade_list_items
    add_column :wantlist_items, :condition, :string, default: "NM", null: false
    add_column :trade_list_items, :condition, :string, default: "NM", null: false

    # Set default on existing collection_items.condition column
    change_column_default :collection_items, :condition, from: nil, to: "NM"
    change_column_null :collection_items, :condition, false, "NM"

    # Remove unique indexes to allow multiples
    remove_index :collection_items, [:collection_id, :release_id]
    remove_index :wantlist_items, [:user_id, :release_id]
    remove_index :trade_list_items, [:user_id, :release_id]

    # Re-add as non-unique for query performance
    add_index :collection_items, [:collection_id, :release_id]
    add_index :wantlist_items, [:user_id, :release_id]
    add_index :trade_list_items, [:user_id, :release_id]
  end
end
