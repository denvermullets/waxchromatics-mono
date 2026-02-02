class Release < ApplicationRecord
  belongs_to :master
  has_many :tracks, dependent: :destroy
  has_many :release_artists, dependent: :destroy
  has_many :artists, through: :release_artists
  has_many :release_labels, dependent: :destroy
  has_many :labels, through: :release_labels
  has_many :release_formats, dependent: :destroy
  has_many :collection_items, dependent: :destroy

  validates :title, presence: true
end
