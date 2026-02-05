class DashboardController < ApplicationController
  def show; end

  PER_PAGE = 25

  def search
    @query = params[:query].to_s.strip
    @page = [params[:page].to_i, 1].max
    return if @query.blank?

    # Always query both sources
    @local_results = search_local_artists(@query, @page)
    @external_results = search_external_artists(@query, @page)

    # Fire ingest for FIRST external result only
    enqueue_first_artist_ingest(@external_results[:artists].first)

    # Top result prefers local
    @top_artist = @local_results[:artists].first
    @key_releases = @top_artist&.releases&.limit(4) || []
  end

  private

  def search_local_artists(query, page)
    results = Artist.where('name ILIKE ?', "%#{query}%")
    total = results.count
    artists = results.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
    { artists: artists, total_pages: (total.to_f / PER_PAGE).ceil, total_count: total }
  end

  def search_external_artists(query, page)
    WaxApiClient::SearchArtists.call(query: query, page: page)
  end

  def enqueue_first_artist_ingest(artist_data)
    return if artist_data.blank? || !artist_data.is_a?(Hash)

    discogs_id = artist_data['id']
    return if discogs_id.blank?
    return if Artist.exists?(discogs_id: discogs_id)
    return if PendingIngest.exists?(discogs_id: discogs_id, resource_type: 'Artist')

    PendingIngest.create!(
      discogs_id: discogs_id,
      resource_type: 'Artist',
      status: 'pending',
      metadata: artist_data
    )
    IngestArtistJob.perform_later(artist_data)
  end
end
