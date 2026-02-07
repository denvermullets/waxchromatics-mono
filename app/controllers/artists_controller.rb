class ArtistsController < ApplicationController
  def show
    @page = [params[:page].to_i, 1].max
    load_artist
    extract_api_details
  end

  def search
    artists = Artist.where('name ILIKE ?', "%#{params[:q]}%").order(:name).limit(10)
    render json: artists.map { |a| { id: a.id, name: a.name } }
  end

  private

  def load_artist
    @artist = Artist.find_by(id: params[:id]) || Artist.find_by(discogs_id: params[:id])
    @local_releases = @artist&.releases || Release.none
    load_discography
    load_api_sidebar
  end

  def load_discography
    per_page = 25
    all_groups = @artist&.release_groups&.order(:year) || ReleaseGroup.none
    @total_pages = (all_groups.count.to_f / per_page).ceil.clamp(1..)
    @release_groups = all_groups.offset((@page - 1) * per_page).limit(per_page)
  end

  def load_api_sidebar
    discogs_id = @artist&.discogs_id
    return unless discogs_id

    result = WaxApiClient::ArtistDiscography.call(id: discogs_id, page: 1)
    @api_artist = result[:artist]
  rescue StandardError
    @api_artist = nil
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
