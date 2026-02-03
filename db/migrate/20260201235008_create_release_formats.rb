class CreateReleaseFormats < ActiveRecord::Migration[8.1]
  def change
    create_table :release_formats do |t|
      t.references :release, null: false, foreign_key: true
      t.string :name
      t.integer :quantity
      t.text :descriptions

      t.timestamps
    end
  end
end
