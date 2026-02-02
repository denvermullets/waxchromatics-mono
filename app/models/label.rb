class Label < ApplicationRecord
  has_many :release_labels, dependent: :destroy
  has_many :releases, through: :release_labels
  belongs_to :parent_label, class_name: 'Label', optional: true
  has_many :sub_labels, class_name: 'Label', foreign_key: :parent_label_id

  validates :name, presence: true
end
