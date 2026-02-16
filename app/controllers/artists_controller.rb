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
    @artist = Artist.find_by(id: params[:id]) || Artist.find_by(discogs_id: params[:id])
    @local_releases = @artist&.releases || Release.none
    load_discography
    load_appearances
  end

  def load_discography
    @sections = RELEASE_TYPE_ORDER.filter_map do |type|
      groups = @artist&.release_groups
      scope = groups ? groups.where(release_type: type).order(:year) : ReleaseGroup.none
      next if scope.none?

      pagy_obj, records = pagy(:offset, scope, limit: DISCOGRAPHY_PER_PAGE, page_key: 'page')
      { type: type, pagy: pagy_obj, release_groups: records }
    end
  end

  def load_appearances
    @appearances = []
    return unless @artist

    rg_ids_by_role = appearance_rg_ids_by_role
    return if rg_ids_by_role.empty?

    @appearances = build_appearances(rg_ids_by_role)
  end

  def appearance_rg_ids_by_role
    @artist.release_contributors
           .where.not(role: [nil, ''])
           .joins(release: :release_group)
           .select('release_contributors.role, release_groups.id AS release_group_id')
           .distinct
           .each_with_object({}) { |rc, hash| (hash[rc.role] ||= Set.new) << rc.release_group_id }
  end

  def build_appearances(rg_ids_by_role)
    all_rg_ids = rg_ids_by_role.values.reduce(:+).to_a
    rg_lookup = ReleaseGroup.where(id: all_rg_ids).includes(releases: :artist).index_by(&:id)

    rg_ids_by_role.sort_by { |role, _| role.downcase }.filter_map do |role, rg_ids|
      rgs = rg_ids.filter_map { |id| rg_lookup[id] }.sort_by { |rg| rg.year || 0 }
      { role: role, release_groups: rgs } if rgs.any?
    end
  end
end
