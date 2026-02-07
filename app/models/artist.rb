class Artist < ApplicationRecord
  has_many :release_artists, dependent: :destroy
  has_many :releases, through: :release_artists
  has_many :release_groups, -> { distinct }, through: :releases

  validates :name, presence: true
end
