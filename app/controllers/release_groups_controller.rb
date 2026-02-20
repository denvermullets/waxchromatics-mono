class ReleaseGroupsController < ApplicationController
  BROWSE_PER_PAGE = 60

  def index
    @sort = params[:sort].presence || 'artist_az'
    @view = params[:view].presence || 'grid'
    @filters = browse_filters
    @letter = @filters[:letter]

    load_dropdown_options
    load_stats
    load_browse_results
  end

  def search
    release_groups = ReleaseGroup.where('title ILIKE ?', "%#{params[:q]}%")
                                 .order(:title).limit(10)
    render json: release_groups.map { |rg|
      { id: rg.id, title: rg.title, year: rg.year, cover_art_url: rg.cover_art_url }
    }
  end

  def show
    load_release_group
    @collection_counts = Collections::OwnershipQuery.new(Current.user).by_release(@releases.map(&:id))
  end

  private

  def load_release_group
    @release_group = ReleaseGroup.find(params[:id])
    @releases = @release_group.releases
                              .includes(:release_formats, :tracks, :artist,
                                        release_labels: :label, release_contributors: :artist)
                              .order(:released)
    @artist = Artist.find(params[:artist_id])
    @artists = [@artist]
    main_release = @releases.find { |r| r.discogs_id == @release_group.main_release_id } || @releases.first
    @main_release = main_release
    @tracklist = main_release&.tracks&.order(:sequence) || Track.none
  end

  def load_stats
    base = ReleaseGroup.joins(:releases).where.not(releases: { artist_id: nil })
    @total_release_groups = base.distinct.count
    @total_variants = Release.where.not(release_group_id: nil).count
    @total_labels = Label.joins(release_labels: :release)
                         .where.not(releases: { release_group_id: nil })
                         .distinct.count
    @total_genres = ReleaseGenre.joins(:release)
                                .where.not(releases: { release_group_id: nil })
                                .distinct.count(:genre)
  end

  def load_dropdown_options
    release_with_rg = Release.where.not(release_group_id: nil)
    @label_options = Label.joins(release_labels: :release)
                          .where(releases: { id: release_with_rg })
                          .distinct.order(:name).pluck(:name)
    @genre_options = ReleaseGenre.joins(:release)
                                 .where(releases: { id: release_with_rg })
                                 .distinct.order(:genre).pluck(:genre)
    @country_options = release_with_rg.where.not(country: [nil, ''])
                                      .distinct.order(:country).pluck(:country)
  end

  def load_browse_results
    query = ReleaseGroups::BrowseQuery.new(
      params: params, filters: @filters, sort: @sort,
      page: (params[:page] || 1).to_i, limit: BROWSE_PER_PAGE
    ).call

    @pagy = query.pagy
    @release_groups = query.release_groups
    @variant_counts = query.variant_counts
    @grouped = query.grouped
    @available_letters = query.available_letters
  end

  def browse_filters
    letter = params[:letter].presence
    letter ||= 'A' if default_letter?

    {
      letter: letter,
      format: params[:format_filter].presence,
      decade: params[:decade].presence,
      label: params[:label].presence,
      genre: params[:genre].presence,
      country: params[:country].presence,
      colored: params[:colored] == '1'
    }
  end

  def default_letter?
    %w[artist_az artist_za].include?(@sort) && params[:q].blank?
  end
end
