class ArtistsController < ApplicationController
  def show
    @page = [params[:page].to_i, 1].max
    load_artist
    extract_api_details
  end

  private

  def load_artist
    local_artist = Artist.find_by(id: params[:id]) || Artist.find_by(discogs_id: params[:id])
    discogs_id = local_artist&.discogs_id || params[:id]
    result = WaxApiClient::ArtistDiscography.call(id: discogs_id, page: @page)

    @artist = local_artist
    @api_artist = result[:artist]
    @masters = result[:masters]
    @pagy = result[:pagy]
    @local_releases = local_artist&.releases || Release.none
  end

  def extract_api_details
    @members = @api_artist&.dig('members') || []
    @urls = extract_nested(@api_artist&.dig('artist_urls'), 'url')
    @name_variations = extract_nested(@api_artist&.dig('artist_namevariations'), 'name')
  end

  def extract_nested(collection, key)
    (collection || []).map { |item| item.is_a?(Hash) ? item[key] : item }
  end
end
