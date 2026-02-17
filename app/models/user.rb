class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :wantlist_items, dependent: :destroy
  has_many :trade_list_items, dependent: :destroy
  has_many :collection_imports, dependent: :destroy
  has_many :initiated_trades, class_name: 'Trade', foreign_key: :initiator_id, dependent: :destroy
  has_many :received_trades, class_name: 'Trade', foreign_key: :recipient_id, dependent: :destroy
  has_many :trade_messages, dependent: :destroy
  has_many :trade_shipments, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  RESERVED_USERNAMES = %w[session registration passwords releases artists search up jobs admin settings trades].freeze

  validates :username, presence: true, uniqueness: true,
                       format: {
                         with: /\A[a-zA-Z0-9_-]+\z/,
                         message: 'only allows letters, numbers, underscores, and hyphens'
                       },
                       exclusion: { in: RESERVED_USERNAMES, message: 'is reserved' }
  validates :default_collection_view, inclusion: { in: %w[grid list] }

  def default_collection
    collections.first_or_create!(name: 'My Collection')
  end
end
