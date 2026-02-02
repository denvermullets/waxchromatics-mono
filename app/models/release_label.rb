class ReleaseLabel < ApplicationRecord
  belongs_to :release
  belongs_to :label, optional: true
end
