class Artist < ApplicationRecord
  has_many :release_artists, dependent: :destroy
  has_many :releases, through: :release_artists

  validates :name, presence: true
end
