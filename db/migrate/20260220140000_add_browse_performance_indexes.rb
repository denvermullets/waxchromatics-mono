class AddBrowsePerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :artists, :name
    add_index :release_groups, :year
  end
end
