class ReleaseGroup < ApplicationRecord
  has_many :releases, dependent: :nullify

  validates :title, presence: true
end
