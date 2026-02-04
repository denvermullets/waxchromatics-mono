module MusicBrainzClient
  class ReleaseLookup < Service
    BASE_URL = 'https://musicbrainz.org/ws/2'.freeze

    def initialize(discogs_release_id:, artist_name: nil, title: nil)
      @discogs_release_id = discogs_release_id
      @artist_name = artist_name
      @title = title
    end

    def call
      mbid = lookup_by_discogs_url
      return mbid if mbid.present?

      search_by_artist_and_title
    rescue StandardError => e
      Rails.logger.error("[MusicBrainzClient::ReleaseLookup] Error: #{e.message}")
      nil
    end

    private

    def lookup_by_discogs_url
      return nil if @discogs_release_id.blank?

      response = HTTParty.get(
        "#{BASE_URL}/url",
        query: { resource: "https://www.discogs.com/release/#{@discogs_release_id}", inc: 'release-rels', fmt: 'json' },
        headers: headers
      )

      return nil unless response.success?

      relations = response.parsed_response['relations']
      return nil if relations.blank?

      rel = relations.find { |r| r['type'] == 'discogs' && r['target-type'] == 'release' }
      rel&.dig('release', 'id')
    end

    def search_by_artist_and_title
      return nil if @artist_name.blank? || @title.blank?

      sleep(1.2)

      query = %(artist:"#{@artist_name}" AND release:"#{@title}")
      response = HTTParty.get(
        "#{BASE_URL}/release/",
        query: { query: query, fmt: 'json', limit: 1 },
        headers: headers
      )

      return nil unless response.success?

      releases = response.parsed_response['releases']
      return nil if releases.blank?

      best = releases.first
      return nil if best['score'].to_i < 90

      best['id']
    end

    def headers
      { 'User-Agent' => 'WaxChromatics/1.0 (https://github.com/denvermullets/waxchromatics-mono)' }
    end
  end
end
