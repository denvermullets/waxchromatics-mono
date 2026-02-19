class AddDefaultCollectionViewToUserSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_settings, :collection_list_view, :boolean, default: false, null: false
  end
end
