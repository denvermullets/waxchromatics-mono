class CreateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :versions do |t|
      t.string   :whodunnit
      t.datetime :created_at
      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.jsonb    :object
      t.bigint   :collection_import_id
      t.bigint   :release_id
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, :created_at
    add_index :versions, :collection_import_id
    add_index :versions, %i[whodunnit item_type created_at], name: "index_versions_on_whodunnit_item_type_created_at"
  end
end
