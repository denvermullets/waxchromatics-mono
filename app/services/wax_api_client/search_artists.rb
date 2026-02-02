module WaxApiClient
  class SearchArtists < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(query:)
      @query = query
    end

    def call
      uri = URI("#{BASE_URL}/artists")
      uri.query = URI.encode_www_form(query: @query)

      response = Net::HTTP.get_response(uri)
      return [] unless response.is_a?(Net::HTTPSuccess)

      parsed = JSON.parse(response.body)
      parsed.fetch('data', [])
    rescue StandardError
      []
    end
  end
end
