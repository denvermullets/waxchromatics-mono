class DashboardController < ApplicationController
  def show; end

  PER_PAGE = 25

  def search
    @query = params[:query].to_s.strip
    @page = [params[:page].to_i, 1].max
    result = search_artists(@query, @page)
    @artists = result[:artists]
    @total_pages = result[:total_pages]
    @total_count = result[:total_count]
    @top_artist = @artists.first
    @key_releases = if @top_artist.is_a?(Artist)
                      @top_artist.releases.limit(4)
                    else
                      []
                    end
  end

  private

  def search_artists(query, page)
    return { artists: [], total_pages: 0, total_count: 0 } if query.blank?

    local_results = Artist.where('name ILIKE ?', "%#{query}%")
    if local_results.any?
      total = local_results.count
      artists = local_results.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
      { artists: artists, total_pages: (total.to_f / PER_PAGE).ceil, total_count: total }
    else
      result = WaxApiClient::SearchArtists.call(query: query, page: page)
      enqueue_artist_ingestion(result[:artists])
      result
    end
  end

  def enqueue_artist_ingestion(artists)
    return if artists.blank?

    artists.each do |artist|
      next unless artist.is_a?(Hash) && artist['id'].present?

      IngestArtistJob.perform_later(artist)
    end
  end
end
