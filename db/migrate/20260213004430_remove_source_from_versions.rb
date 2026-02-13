class RemoveSourceFromVersions < ActiveRecord::Migration[8.1]
  def change
    remove_column :versions, :source, :string
  end
end
