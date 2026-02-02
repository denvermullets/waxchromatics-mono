class CreateCollectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_items do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true
      t.string :condition
      t.text :notes
      t.decimal :purchase_price, precision: 10, scale: 2
      t.decimal :sale_price, precision: 10, scale: 2
      t.date :purchase_date
      t.date :sale_date
      t.string :status

      t.timestamps
    end
    add_index :collection_items, [ :collection_id, :release_id ]
  end
end
