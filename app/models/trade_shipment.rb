class TradeShipment < ApplicationRecord
  has_paper_trail

  STATUSES = %w[pending shipped in_transit delivered].freeze

  belongs_to :trade
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :trade_id, message: 'already has a shipment for this trade' }
  validate :trade_must_be_accepted

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  private

  def trade_must_be_accepted
    errors.add(:trade, 'must be accepted') unless trade&.accepted?
  end
end
