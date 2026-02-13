module Connections
  class PathEnricher < Service
    def initialize(path)
      @path = path
    end

    def call
      return if @path.empty?

      artists = load_artists
      releases = load_releases

      @path.each { |edge| enrich_edge(edge, artists, releases) }
    end

    private

    def load_artists
      ids = @path.flat_map { |e| [e[:from_artist_id], e[:to_artist_id]] }.uniq
      Artist.where(id: ids).index_by(&:id)
    end

    def load_releases
      ids = @path.filter_map { |e| e[:release_id] }.uniq
      Release.includes(:release_group).where(id: ids).index_by(&:id)
    end

    def enrich_edge(edge, artists, releases)
      edge[:from_artist] = artists[edge[:from_artist_id]]
      edge[:to_artist] = artists[edge[:to_artist_id]]
      release = releases[edge[:release_id]]
      edge[:release] = release
      edge[:release_group] = release&.release_group
      edge[:label] = release&.title
      edge[:year] = release&.release_group&.year
    end
  end
end
