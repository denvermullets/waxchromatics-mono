class TradeItem < ApplicationRecord
  belongs_to :trade
  belongs_to :user
  belongs_to :release
  belongs_to :collection_item

  validates :collection_item_id, uniqueness: { scope: :trade_id }
  validate :item_belongs_to_user

  private

  def item_belongs_to_user
    return unless collection_item && user

    return if collection_item.collection.user_id == user.id

    errors.add(:collection_item, "must belong to the user's collection")
  end
end
