class ReleaseIdentifier < ApplicationRecord
  belongs_to :release

  validates :identifier_type, presence: true
  validates :value, presence: true
end
