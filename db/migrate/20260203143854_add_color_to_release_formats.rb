class AddColorToReleaseFormats < ActiveRecord::Migration[8.1]
  def change
    add_column :release_formats, :color, :string
  end
end
