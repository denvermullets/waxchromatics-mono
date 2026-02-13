class AddSourceToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :source, :string
  end
end
