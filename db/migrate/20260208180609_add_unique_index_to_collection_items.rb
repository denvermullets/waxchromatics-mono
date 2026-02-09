class AddUniqueIndexToCollectionItems < ActiveRecord::Migration[8.1]
  def change
    remove_index :collection_items, [:collection_id, :release_id]
    add_index :collection_items, [:collection_id, :release_id], unique: true
  end
end
