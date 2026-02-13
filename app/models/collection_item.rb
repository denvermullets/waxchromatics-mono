class CollectionItem < ApplicationRecord
  has_paper_trail meta: {
    collection_import_id: :paper_trail_collection_import_id,
    release_id: :release_id
  }

  belongs_to :collection
  belongs_to :release
  has_one :trade_list_item, dependent: :destroy

  private

  def paper_trail_collection_import_id
    PaperTrail.request.controller_info&.dig(:collection_import_id)
  end
end
