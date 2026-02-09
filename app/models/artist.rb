class Artist < ApplicationRecord
  has_many :releases, dependent: :nullify
  has_many :release_contributors, dependent: :destroy
  has_many :contributed_releases, through: :release_contributors, source: :release
  has_many :release_groups, -> { distinct }, through: :releases

  validates :name, presence: true
end
