class ReleaseGenre < ApplicationRecord
  belongs_to :release

  validates :genre, presence: true, uniqueness: { scope: :release_id }
end
