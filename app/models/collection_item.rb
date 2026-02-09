class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :release
  has_one :trade_list_item, dependent: :destroy
end
