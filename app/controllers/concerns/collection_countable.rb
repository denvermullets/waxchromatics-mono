module CollectionCountable
  extend ActiveSupport::Concern

  private

  def collection_counts_by_release_group(rg_ids)
    return {} unless Current.user

    CollectionItem
      .where(collection: Current.user.default_collection)
      .joins(:release)
      .where(releases: { release_group_id: rg_ids })
      .group('releases.release_group_id')
      .count
  end

  def collection_counts_by_release(release_ids)
    return {} unless Current.user

    CollectionItem
      .where(collection: Current.user.default_collection, release_id: release_ids)
      .group(:release_id)
      .count
  end
end
