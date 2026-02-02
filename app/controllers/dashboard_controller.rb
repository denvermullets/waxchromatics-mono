class DashboardController < ApplicationController
  def show; end

  def search
    @query = params[:query].to_s.strip
    @artists = search_artists(@query)
  end

  private

  def search_artists(query)
    return [] if query.blank?

    local_results = Artist.where('name ILIKE ?', "%#{query}%")
    return local_results if local_results.any?

    WaxApiClient::SearchArtists.call(query: query)
  end
end
