module WaxApiClient
  class SearchArtists < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(query:, page: 1, per_page: 25)
      @query = query
      @page = page
      @per_page = per_page
    end

    def call
      response = HTTParty.get("#{BASE_URL}/artists", query: { query: @query, page: @page, limit: @per_page })
      return { artists: [], total_pages: 0, total_count: 0 } unless response.success?

      parsed = response.parsed_response
      artists = parsed.fetch('data', [])
      pagy = parsed.fetch('pagy', {})
      { artists: artists, total_pages: pagy.fetch('last', 1), total_count: pagy.fetch('count', artists.size) }
    rescue StandardError
      { artists: [], total_pages: 0, total_count: 0 }
    end
  end
end
