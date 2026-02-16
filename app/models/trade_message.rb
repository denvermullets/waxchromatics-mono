class TradeMessage < ApplicationRecord
  belongs_to :trade
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }
end
