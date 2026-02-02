class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :username, presence: true, uniqueness: true
end
