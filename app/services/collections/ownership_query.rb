module Collections
  class OwnershipQuery
    def initialize(user)
      @collection = user&.default_collection
    end

    def by_release_group(rg_ids)
      return {} unless @collection

      CollectionItem
        .where(collection: @collection)
        .joins(:release)
        .where(releases: { release_group_id: rg_ids })
        .group('releases.release_group_id')
        .count
    end

    def by_release(release_ids)
      return {} unless @collection

      CollectionItem
        .where(collection: @collection, release_id: release_ids)
        .group(:release_id)
        .count
    end
  end
end
