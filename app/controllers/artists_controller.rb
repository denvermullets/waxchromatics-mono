class ArtistsController < ApplicationController
  def show
    @page = [params[:page].to_i, 1].max
    load_artist
    extract_api_details
  end

  def new
    @artist = Artist.new
  end

  def create
    @artist = Artist.new(artist_params)
    if @artist.save
      associate_release_groups
      redirect_to artist_path(@artist), notice: 'Artist created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @artist = Artist.find(params[:id])
    @existing_release_groups = @artist.release_groups.distinct.map do |rg|
      { id: rg.id, title: rg.title, year: rg.year, cover_art_url: rg.releases.first&.cover_art_url }
    end
  end

  def update
    @artist = Artist.find(params[:id])
    if @artist.update(artist_params)
      associate_release_groups
      redirect_to artist_path(@artist), notice: 'Artist updated.'
    else
      @existing_release_groups = @artist.release_groups.distinct.map do |rg|
        { id: rg.id, title: rg.title, year: rg.year, cover_art_url: rg.releases.first&.cover_art_url }
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def search
    artists = Artist.where('name ILIKE ?', "%#{params[:q]}%").order(:name).limit(10)
    render json: artists.map { |a| { id: a.id, name: a.name } }
  end

  private

  def artist_params
    params.require(:artist).permit(:name, :real_name, :profile, :discogs_id)
  end

  def associate_release_groups
    release_group_ids = params[:artist][:release_group_ids]&.reject(&:blank?) || []
    ReleaseArtist.where(artist: @artist).destroy_all
    release_group_ids.each { |rg_id| link_release_group(rg_id) }
  end

  def link_release_group(rg_id)
    release = ReleaseGroup.find_by(id: rg_id)&.releases&.first
    return unless release

    ReleaseArtist.find_or_create_by(artist: @artist, release: release) do |ra|
      ra.position = 0
    end
  end

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
