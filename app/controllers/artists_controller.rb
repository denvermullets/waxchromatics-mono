class ArtistsController < ApplicationController
  RELEASE_TYPE_ORDER = ['Album', 'EP', 'Single', 'Compilation', 'Unofficial Release'].freeze
  DISCOGRAPHY_PER_PAGE = 25
  ARTISTS_PER_PAGE = 250
  FIRST_ALPHA_SQL = "UPPER(SUBSTRING(name FROM '[A-Za-z]'))".freeze
  ALPHA_ORDER_SQL = "#{FIRST_ALPHA_SQL}, name".freeze

  def index
    @filter = params[:filter].presence || 'primary'
    @letter = params[:letter].presence
    load_artist_browse
  end

  def show
    load_artist
  end

  def discography_section
    @artist = Artist.find(params[:id])
    release_type = params[:release_type]
    return head(:bad_request) unless RELEASE_TYPE_ORDER.include?(release_type)

    scope = @artist.release_groups.where(release_type: release_type).order(:year)
    @pagy, @release_groups = pagy(:offset, scope, limit: DISCOGRAPHY_PER_PAGE, page_key: 'page')
    @release_type = release_type
    @collection_counts = Collections::OwnershipQuery.new(Current.user).by_release_group(@release_groups.map(&:id))

    render partial: 'artists/discography_section', locals: {
      artist: @artist, pagy: @pagy, release_groups: @release_groups, release_type: release_type
    }
  end

  def discography_type
    @artist = Artist.find(params[:id])
    @release_type = params[:release_type]
    return head(:bad_request) unless RELEASE_TYPE_ORDER.include?(@release_type)

    @release_groups = @artist.release_groups.where(release_type: @release_type).order(:year)
    @local_releases = @artist.releases
    @collection_counts = Collections::OwnershipQuery.new(Current.user).by_release_group(@release_groups.map(&:id))
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
    @artist.releases.update_all(artist_id: nil)
    releases = Release.where(release_group_id: release_group_ids)
    releases.update_all(artist_id: @artist.id)
  end

  def load_artist_browse
    base_scope = artist_browse_scope
    @available_letters = base_scope.pluck(Arel.sql(FIRST_ALPHA_SQL)).compact.uniq.sort

    scope = filter_artist_scope(base_scope)
    @pagy, @artists = pagy(scope, limit: ARTISTS_PER_PAGE)
    @grouped_artists = @artists.group_by { |a| a.name[/[A-Za-z]/]&.upcase || '#' }
    load_artist_counts
  end

  def filter_artist_scope(scope)
    scope = scope.order(Arel.sql(ALPHA_ORDER_SQL))
    scope = scope.where('name ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    scope = scope.where("#{FIRST_ALPHA_SQL} = ?", @letter) if @letter.present?
    scope
  end

  def load_artist_counts
    artist_ids = @artists.map(&:id)
    @release_counts = release_group_counts_for(artist_ids)
    @variant_counts = Release.where(artist_id: artist_ids).group(:artist_id).count
  end

  def artist_browse_scope
    @filter == 'all' ? Artist.all : Artist.where(id: Release.select(:artist_id))
  end

  def release_group_counts_for(artist_ids)
    ReleaseGroup.joins(:releases)
                .where(releases: { artist_id: artist_ids })
                .group('releases.artist_id')
                .count('DISTINCT release_groups.id')
  end

  def load_artist
    artist = Artist.find_by(id: params[:id]) || Artist.find_by(discogs_id: params[:id])
    paginate = ->(scope) { pagy(:offset, scope, limit: DISCOGRAPHY_PER_PAGE, page_key: 'page') }

    result = Artists::ShowQuery.new(
      artist: artist, tab: params[:tab].presence || 'discography', user: Current.user, paginate: paginate
    ).call

    assign_show_ivars(result)
  end

  def assign_show_ivars(result)
    %i[artist tab has_appearances sections appearances local_releases collection_counts].each do |attr|
      instance_variable_set(:"@#{attr}", result.public_send(attr))
    end
  end
end
