class CreateReleaseStyles < ActiveRecord::Migration[8.1]
  def change
    create_table :release_styles do |t|
      t.references :release, null: false, foreign_key: true
      t.string :style, null: false

      t.timestamps
    end

    add_index :release_styles, [:release_id, :style], unique: true
  end
end
