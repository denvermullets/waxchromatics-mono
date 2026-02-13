module Connections
  class NeighborQuery < Service
    def initialize(artist_ids)
      @artist_ids = artist_ids
      @edges = Hash.new { |h, k| h[k] = [] }
    end

    def call
      add_primary_to_contributor_edges
      add_contributor_to_primary_edges
      add_co_contributor_edges
      deduplicate
      @edges
    end

    private

    # Releases where these artists are primary → find contributors on those releases
    def add_primary_to_contributor_edges
      release_map = primary_release_map
      return if release_map.empty?

      ReleaseContributor.where(release_id: release_map.keys)
                        .where.not(artist_id: @artist_ids)
                        .select(:artist_id, :release_id, :role)
                        .each do |rc|
                          from_id = release_map[rc.release_id]
                          @edges[from_id] << { neighbor_id: rc.artist_id, release_id: rc.release_id,
                                               role: rc.role, from_id: from_id }
      end
    end

    # Releases where these artists are contributors → find primary artist
    def add_contributor_to_primary_edges
      return if contributor_map.empty?

      Release.where(id: contributor_map.keys)
             .where.not(artist_id: [nil] + @artist_ids)
             .select(:id, :artist_id)
             .each do |r|
               contributor_map[r.id]&.each do |entry|
                 @edges[entry[:artist_id]] << { neighbor_id: r.artist_id, release_id: r.id,
                                                role: entry[:role], from_id: entry[:artist_id] }
               end
      end
    end

    # Co-contributors on the same release
    def add_co_contributor_edges
      return if contributor_map.empty?

      co_contributors = ReleaseContributor.where(release_id: contributor_map.keys)
                                          .where.not(artist_id: @artist_ids)
                                          .select(:artist_id, :release_id, :role)
      co_contributors.each { |rc| append_co_contributor_edges(rc) }
    end

    def append_co_contributor_edges(contributor)
      contributor_map[contributor.release_id]&.each do |entry|
        @edges[entry[:artist_id]] << {
          neighbor_id: contributor.artist_id, release_id: contributor.release_id,
          role: [entry[:role], contributor.role].compact.join(' / '), from_id: entry[:artist_id]
        }
      end
    end

    def deduplicate
      @edges.each_key do |artist_id|
        @edges[artist_id] = @edges[artist_id].uniq { |e| [e[:neighbor_id], e[:release_id]] }
      end
    end

    def primary_release_map
      @primary_release_map ||= Release.where(artist_id: @artist_ids)
                                      .select(:id, :artist_id)
                                      .each_with_object({}) { |r, h| h[r.id] = r.artist_id }
    end

    def contributor_map
      @contributor_map ||= ReleaseContributor.where(artist_id: @artist_ids)
                                             .select(:artist_id, :release_id, :role)
                                             .each_with_object({}) do |rc, h|
                                               (h[rc.release_id] ||= []) << { artist_id: rc.artist_id, role: rc.role }
      end
    end
  end
end
