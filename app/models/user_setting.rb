class UserSetting < ApplicationRecord
  belongs_to :user

  THEMES = %w[ember slate moss].freeze

  validates :theme, inclusion: { in: THEMES }
  validates :auto_decline_days, inclusion: { in: 1..30 }
end
