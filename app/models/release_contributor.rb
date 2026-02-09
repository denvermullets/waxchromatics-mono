class ReleaseContributor < ApplicationRecord
  belongs_to :release
  belongs_to :artist
end
