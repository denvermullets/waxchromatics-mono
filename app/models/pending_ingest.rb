class PendingIngest < ApplicationRecord
  validates :discogs_id, presence: true
  validates :status, inclusion: { in: %w[pending completed failed] }

  def processing?
    status == 'pending'
  end
end
