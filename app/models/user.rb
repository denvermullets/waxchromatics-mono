class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :wantlist_items, dependent: :destroy
  has_many :trade_list_items, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :username, presence: true, uniqueness: true

  def default_collection
    collections.first_or_create!(name: 'My Collection')
  end
end
