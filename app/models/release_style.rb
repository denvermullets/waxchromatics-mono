class ReleaseStyle < ApplicationRecord
  belongs_to :release

  validates :style, presence: true, uniqueness: { scope: :release_id }
end
