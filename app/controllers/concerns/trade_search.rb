module TradeSearch
  extend ActiveSupport::Concern

  def search_collection_items(user, query)
    return [] if query.blank? || query.length < 2

    CollectionItem.joins(:collection, release: %i[artist release_group])
                  .where(collections: { user_id: user.id })
                  .where('releases.title ILIKE :q OR artists.name ILIKE :q', q: "%#{query}%")
                  .includes(release: %i[artist release_group release_formats])
                  .limit(20)
  end

  def load_collection_items(ci_ids)
    return [] if ci_ids.blank?

    CollectionItem.where(id: Array(ci_ids))
                  .includes(release: %i[artist release_group release_formats])
  end
end
