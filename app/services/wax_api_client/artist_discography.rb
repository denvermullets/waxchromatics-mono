module WaxApiClient
  class ArtistDiscography < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(id:, page: 1, limit: 10)
      @id = id
      @page = page
      @limit = limit
    end

    def call
      response = HTTParty.get("#{BASE_URL}/artists/#{@id}/discography", query: { page: @page, limit: @limit })
      return empty_result unless response.success?

      parsed = response.parsed_response
      data = parsed.fetch('data', {})
      artist = data.fetch('artist', {})
      masters = data.fetch('masters', [])
      pagy = parsed.fetch('pagy', {})

      {
        artist: artist,
        masters: masters,
        pagy: pagy
      }
    rescue StandardError
      empty_result
    end

    private

    def empty_result
      { artist: {}, masters: [], pagy: {} }
    end
  end
end
