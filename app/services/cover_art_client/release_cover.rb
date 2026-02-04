module CoverArtClient
  class ReleaseCover < Service
    BASE_URL = 'https://coverartarchive.org'.freeze

    def initialize(musicbrainz_id:)
      @musicbrainz_id = musicbrainz_id
    end

    def call
      return nil if @musicbrainz_id.blank?

      images = fetch_images
      return nil if images.blank?

      front = images.find { |img| img['front'] } || images.first
      front.dig('thumbnails', '1200') || front['image']
    rescue StandardError
      nil
    end

    private

    def fetch_images
      response = HTTParty.get("#{BASE_URL}/release/#{@musicbrainz_id}")
      return nil unless response.success?

      response.parsed_response['images']
    end
  end
end
