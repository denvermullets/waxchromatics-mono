class CreateReleaseLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :release_labels do |t|
      t.references :release, null: false, foreign_key: true
      t.references :label, foreign_key: true
      t.string :catalog_number

      t.timestamps
    end
    add_index :release_labels, [ :release_id, :label_id ]
  end
end
