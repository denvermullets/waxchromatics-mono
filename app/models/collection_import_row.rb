class CollectionImportRow < ApplicationRecord
  belongs_to :collection_import
  belongs_to :release, optional: true
end
