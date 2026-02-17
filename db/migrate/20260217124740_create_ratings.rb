class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.string :rateable_type, null: false
      t.bigint :rateable_id, null: false
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_user, null: false, foreign_key: { to_table: :users }
      t.integer :overall_rating, null: false
      t.integer :communication_rating, null: false
      t.integer :packing_shipping_rating, null: false
      t.string :condition_accuracy, null: false
      t.text :tags, array: true, default: []
      t.text :comments

      t.timestamps
    end

    add_index :ratings, [:rateable_type, :rateable_id, :reviewer_id], unique: true, name: 'index_ratings_unique_per_reviewer'
    add_index :ratings, [:rateable_type, :rateable_id]
  end
end
