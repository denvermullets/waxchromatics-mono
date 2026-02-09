class TradeListItem < ApplicationRecord
  belongs_to :user
  belongs_to :release
  belongs_to :collection_item

  validates :release_id, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: %w[available pending traded] }
end
