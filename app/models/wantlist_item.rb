class WantlistItem < ApplicationRecord
  has_paper_trail meta: { release_id: :release_id }

  belongs_to :user
  belongs_to :release
end
