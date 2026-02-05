class DashboardController < ApplicationController
  def show; end

  PER_PAGE = 25

  def search
    @query = params[:query].to_s.strip
    @page = [params[:page].to_i, 1].max
    return if @query.blank?

    # Only fetch local results initially - external loads via lazy Turbo Frame
    @local_results = search_local_artists(@query, @page)

    # Top result from local
    @top_artist = @local_results[:artists].first
    @key_releases = @top_artist&.releases&.limit(4) || []
  end

  def external_search
    @query = params[:query].to_s.strip
    @page = [params[:page].to_i, 1].max

    @external_results = if @query.blank?
                          { artists: [], total_pages: 0, total_count: 0 }
                        else
                          search_external_artists(@query, @page)
                        end

    render partial: 'dashboard/external_results_content'
  end

  def ingest_artist
    artist_data = params.expect(artist: %i[id name thumb]).to_h
    discogs_id = artist_data['id'].to_i
    enqueue_artist_ingest(artist_data.merge('id' => discogs_id))

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "external-artist-#{discogs_id}",
          partial: 'dashboard/artist_row_importing',
          locals: { artist_data: artist_data, discogs_id: discogs_id }
        )
      end
    end
  end

  private

  def search_local_artists(query, page)
    # Strip Discogs-style numeric indicators like (2), (3) from the query for matching
    normalized_query = query.gsub(/\s*\(\d+\)\s*$/, '').strip

    exact_match_sql = <<~SQL.squish
      CASE WHEN REGEXP_REPLACE(artists.name, '\\s*\\(\\d+\\)\\s*$', '') ILIKE ? THEN 0 ELSE 1 END
    SQL

    results = Artist
              .where('name ILIKE ?', "%#{normalized_query}%")
              .left_joins(:release_artists)
              .group('artists.id')
              .order(
                Arel.sql(ActiveRecord::Base.sanitize_sql_array([exact_match_sql, normalized_query])),
                Arel.sql('COUNT(release_artists.id) DESC')
              )

    total = Artist.where('name ILIKE ?', "%#{normalized_query}%").count
    artists = results.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
    { artists: artists, total_pages: (total.to_f / PER_PAGE).ceil, total_count: total }
  end

  def search_external_artists(query, page)
    WaxApiClient::SearchArtists.call(query: query, page: page)
  end

  def enqueue_artist_ingest(artist_data)
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
