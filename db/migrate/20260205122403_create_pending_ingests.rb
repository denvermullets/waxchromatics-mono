class CreatePendingIngests < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_ingests do |t|
      t.integer :discogs_id, null: false
      t.string :resource_type, null: false, default: 'Artist'
      t.string :status, null: false, default: 'pending'
      t.json :metadata

      t.timestamps
    end

    add_index :pending_ingests, [:discogs_id, :resource_type], unique: true
  end
end
