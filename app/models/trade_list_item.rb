class TradeListItem < ApplicationRecord
  has_paper_trail meta: { release_id: :release_id }

  belongs_to :user
  belongs_to :release
  belongs_to :collection_item

  validates :status, inclusion: { in: %w[available pending traded] }
end
