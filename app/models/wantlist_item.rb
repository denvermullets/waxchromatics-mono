class WantlistItem < ApplicationRecord
  belongs_to :user
  belongs_to :release

  validates :release_id, uniqueness: { scope: :user_id }
end
