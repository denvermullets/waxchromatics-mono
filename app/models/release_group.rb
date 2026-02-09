class ReleaseGroup < ApplicationRecord
  has_many :releases, dependent: :nullify
  has_many :release_artists, -> { where(role: [nil, '']) }, through: :releases
  has_many :artists, -> { distinct }, through: :release_artists

  validates :title, presence: true
end
