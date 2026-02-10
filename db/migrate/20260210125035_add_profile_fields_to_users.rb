class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio, :text
    add_column :users, :location, :string
    add_column :users, :avatar_url, :string
    add_column :users, :default_collection_view, :string, default: 'grid', null: false
  end
end
