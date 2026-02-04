module MusicBrainzClient
  class ReleaseGroupLookup < Service
    BASE_URL = 'https://musicbrainz.org/ws/2'.freeze

    def initialize(discogs_master_id:, artist_name: nil, title: nil)
      @discogs_master_id = discogs_master_id
      @artist_name = artist_name
      @title = title
    end

    def call
      mbid = lookup_by_discogs_url
      return mbid if mbid.present?

      search_by_artist_and_title
    rescue StandardError => e
      Rails.logger.error("[MusicBrainzClient::ReleaseGroupLookup] Error: #{e.message}")
      nil
    end

    private

    def lookup_by_discogs_url
      return nil if @discogs_master_id.blank?

      relations = fetch_discogs_relations
      return nil if relations.blank?

      rg = relations.find { |r| r['type'] == 'discogs' && r['target-type'] == 'release_group' }
      rg&.dig('release_group', 'id') || rg&.dig('release-group', 'id')
    end

    def fetch_discogs_relations
      response = HTTParty.get(
        "#{BASE_URL}/url",
        query: {
          resource: "https://www.discogs.com/master/#{@discogs_master_id}",
          inc: 'release-group-rels',
          fmt: 'json'
        },
        headers: headers
      )

      return nil unless response.success?

      response.parsed_response['relations']
    end

    def search_by_artist_and_title
      return nil if @artist_name.blank? || @title.blank?

      sleep(1.2)

      query = %(artist:"#{@artist_name}" AND releasegroup:"#{@title}")
      response = HTTParty.get(
        "#{BASE_URL}/release-group/",
        query: { query: query, fmt: 'json', limit: 1 },
        headers: headers
      )

      return nil unless response.success?

      release_groups = response.parsed_response['release-groups']
      return nil if release_groups.blank?

      best = release_groups.first
      return nil if best['score'].to_i < 90

      best['id']
    end

    def headers
      { 'User-Agent' => 'WaxChromatics/1.0 (https://github.com/denvermullets/waxchromatics-mono)' }
    end
  end
end
