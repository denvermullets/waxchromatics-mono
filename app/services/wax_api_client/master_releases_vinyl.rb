module WaxApiClient
  class MasterReleasesVinyl < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(id:, page: 1, limit: 25)
      @id = id
      @page = page
      @limit = limit
    end

    def call
      response = HTTParty.get(
        "#{BASE_URL}/masters/#{@id}/releases/vinyl",
        query: { page: @page, limit: @limit }
      )
      return empty_result unless response.success?

      parsed = response.parsed_response
      releases = parsed.fetch('data', [])
      pagy = parsed.fetch('pagy', {})

      { releases: releases, pagy: pagy }
    rescue StandardError
      empty_result
    end

    private

    def empty_result
      { releases: [], pagy: {} }
    end
  end
end
