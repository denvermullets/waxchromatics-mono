module WaxApiClient
  class MarkArtistIngested < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(discogs_id:)
      @discogs_id = discogs_id
    end

    def call
      HTTParty.put(
        "#{BASE_URL}/artists/#{@discogs_id}/ingest",
        headers: { 'Content-Type' => 'application/json' }
      )
    rescue StandardError => e
      Rails.logger.error("MarkArtistIngested failed: #{e.message}")
      nil
    end
  end
end
