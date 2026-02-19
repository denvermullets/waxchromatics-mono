class CreateUserSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :user_settings do |t|
      t.string :theme, default: "ember", null: false
      t.boolean :accept_trade_requests, default: true, null: false
      t.integer :auto_decline_days, default: 7, null: false
      t.boolean :require_message_with_trade, default: false, null: false
      t.boolean :private_profile, default: false, null: false
      t.boolean :show_location, default: true, null: false
      t.boolean :notify_trade_updates, default: true, null: false
      t.boolean :notify_messages, default: true, null: false
      t.boolean :notify_wantlist_alerts, default: true, null: false
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
