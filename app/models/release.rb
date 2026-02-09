class Release < ApplicationRecord
  belongs_to :release_group
  belongs_to :artist, optional: true
  has_many :tracks, dependent: :destroy
  has_many :release_contributors, dependent: :destroy
  has_many :credited_artists, through: :release_contributors, source: :artist
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
  accepts_nested_attributes_for :release_contributors, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
end
