class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :release
end
