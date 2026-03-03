class DashboardController < ApplicationController
  def show; end

  def search
    @query = params[:query].to_s.strip
    @page = [params[:page].to_i, 1].max
    return if @query.blank?

    service = Dashboard::SearchQuery.new(query: @query, page: @page, user: Current.user).call
    assign_search_results(service)
    assign_artist_details if @search_type == 'artist'
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
    artist_data = params.require(:artist).permit(:id, :name, :thumb, :profile, :real_name).to_h
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

  def assign_search_results(service)
    @search_type = service.search_type
    @term = service.term
    @results = service.results
    @total_count = service.total_count
    @total_pages = service.total_pages
    @variant_counts = service.variant_counts
    @collection_counts = service.collection_counts
    @roles_map = service.roles_map
    @sample_releases = service.sample_releases
  end

  def assign_artist_details
    @top_artist = @results.first
    @key_releases = @top_artist&.releases&.limit(4) || []
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
