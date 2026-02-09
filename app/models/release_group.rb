class ReleaseGroup < ApplicationRecord
  has_many :releases, dependent: :nullify
  has_many :artists, -> { distinct }, through: :releases, source: :artist

  validates :title, presence: true
end
