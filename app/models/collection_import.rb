class CollectionImport < ApplicationRecord
  belongs_to :user
  has_many :collection_import_rows, dependent: :destroy
end
