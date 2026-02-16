class Trade < ApplicationRecord
  has_paper_trail

  STATUSES = %w[draft proposed accepted declined cancelled].freeze

  belongs_to :initiator, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  belongs_to :proposed_by, class_name: 'User', optional: true
  has_many :trade_items, dependent: :destroy
  has_many :trade_messages, dependent: :destroy
  has_many :trade_shipments, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validate :participants_must_differ

  scope :involving, ->(user) { where(initiator: user).or(where(recipient: user)) }
  scope :with_status, ->(status) { where(status: status) }
  scope :active, -> { where(status: %w[draft proposed]) }

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  def participant?(user)
    initiator_id == user.id || recipient_id == user.id
  end

  def partner_for(user)
    initiator_id == user.id ? recipient : initiator
  end

  def items_from(user)
    trade_items.where(user: user)
  end

  def items_for(user)
    trade_items.where.not(user: user)
  end

  def modifiable?
    draft? || proposed?
  end

  def can_modify?(user)
    participant?(user) && modifiable?
  end

  def proposer?(user)
    proposed_by_id == user.id
  end

  def shipment_for(user)
    trade_shipments.find_by(user: user)
  end

  private

  def participants_must_differ
    errors.add(:recipient, "can't be the same as the initiator") if initiator_id == recipient_id
  end
end
