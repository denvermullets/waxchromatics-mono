module WaxApiClient
  class ArtistDetails < Service
    BASE_URL = ENV.fetch('WAX_API_BASE_URL', 'http://localhost:3030')

    def initialize(id:)
      @id = id
    end

    def call
      response = HTTParty.get("#{BASE_URL}/artists/#{@id}")
      return empty_result unless response.success?

      response.parsed_response
    rescue StandardError
      empty_result
    end

    private

    def empty_result
      {}
    end
  end
end
