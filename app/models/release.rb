class Release < ApplicationRecord
  belongs_to :release_group
  has_many :tracks, dependent: :destroy
  has_many :release_artists, dependent: :destroy
  has_many :artists, through: :release_artists
  has_many :release_labels, dependent: :destroy
  has_many :labels, through: :release_labels
  has_many :release_formats, dependent: :destroy
  has_many :release_identifiers, dependent: :destroy
  has_many :collection_items, dependent: :destroy
  has_many :wantlist_items, dependent: :destroy
  has_many :trade_list_items, dependent: :destroy

  accepts_nested_attributes_for :tracks, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :release_formats, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :release_labels, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :release_identifiers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :release_artists, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
end
