class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :release
  has_one :trade_list_item, dependent: :destroy

  validates :release_id, uniqueness: { scope: :collection_id }
end
