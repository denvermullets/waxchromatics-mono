class Rating < ApplicationRecord
  CONDITION_ACCURACY_VALUES = %w[better_than_listed accurate slightly_off worse_than_listed].freeze
  ALLOWED_TAGS = %w[fast_shipper great_packing friendly smooth_trade generous].freeze

  belongs_to :rateable, polymorphic: true
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewed_user, class_name: 'User'

  validates :overall_rating, :communication_rating, :packing_shipping_rating,
            presence: true, inclusion: { in: 1..5 }
  validates :condition_accuracy, presence: true, inclusion: { in: CONDITION_ACCURACY_VALUES }
  validates :comments, length: { maximum: 500 }
  validates :reviewer_id, uniqueness: { scope: %i[rateable_type rateable_id], message: 'has already rated this' }
  validate :reviewer_must_be_participant
  validate :cannot_rate_self
  validate :rateable_must_be_delivered
  validate :tags_must_be_allowed

  scope :visible, lambda {
    both_rated_ids = Rating.where(rateable_type: 'Trade')
                           .group(:rateable_id)
                           .having('COUNT(*) >= 2')
                           .select(:rateable_id)

    expired_ids = Trade.where(delivered_at: ..7.days.ago).select(:id)

    where(rateable_type: 'Trade', rateable_id: both_rated_ids)
      .or(where(rateable_type: 'Trade', rateable_id: expired_ids))
  }

  def visible?
    counterpart_rated? || time_expired?
  end

  private

  def counterpart_rated?
    Rating.exists?(rateable: rateable, reviewer_id: reviewed_user_id)
  end

  def time_expired?
    return false unless rateable.respond_to?(:delivered_at) && rateable.delivered_at.present?

    rateable.delivered_at <= 7.days.ago
  end

  def reviewer_must_be_participant
    return unless rateable.respond_to?(:participant?)

    errors.add(:reviewer, 'must be a participant') unless rateable.participant?(reviewer)
  end

  def cannot_rate_self
    errors.add(:reviewer, 'cannot rate themselves') if reviewer_id == reviewed_user_id
  end

  def rateable_must_be_delivered
    return unless rateable.respond_to?(:delivered?)

    errors.add(:rateable, 'must be delivered') unless rateable.delivered?
  end

  def tags_must_be_allowed
    return if tags.blank?

    invalid = tags - ALLOWED_TAGS
    errors.add(:tags, "contain invalid values: #{invalid.join(', ')}") if invalid.any?
  end
end
