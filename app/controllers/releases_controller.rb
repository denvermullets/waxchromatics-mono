class ReleasesController < ApplicationController
  def index
    @releases = Release.includes(:release_group, release_artists: :artist).order(created_at: :desc)
  end

  def new
    @release = Release.new
    @release.tracks.build
    @release.release_formats.build
    @release.release_labels.build
    @release.release_identifiers.build
    @release.release_artists.build
    @labels_list = Label.order(:name)
    @artists_list = Artist.order(:name)
  end

  def create
    @release = Release.new(release_params)
    assign_release_group
    assign_primary_artist
    if @release.save
      redirect_to artist_release_group_release_path(@release.artists.first, @release.release_group, @release),
                  notice: 'Release created.'
    else
      @labels_list = Label.order(:name)
      @artists_list = Artist.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @release = Release.includes(
      :release_formats, :tracks, :release_identifiers,
      release_labels: :label,
      release_artists: :artist,
      release_group: :releases
    ).find(params[:id])
    @artist = Artist.find(params[:artist_id])
    @artists = @release.artists
    @release_group = @release.release_group
    @tracklist = @release.tracks.order(:sequence)
    @formats = @release.release_formats
    @labels = @release.release_labels.includes(:label)
    @identifiers = @release.release_identifiers
  end

  private

  def release_params
    params.require(:release).permit(
      :title, :released, :country, :notes, :status, :cover_art_url,
      tracks_attributes: %i[id position title duration sequence _destroy],
      release_formats_attributes: %i[id name quantity descriptions color _destroy],
      release_labels_attributes: %i[id label_id catalog_number _destroy],
      release_identifiers_attributes: %i[id identifier_type value description _destroy],
      release_artists_attributes: %i[id artist_id role position _destroy]
    )
  end

  def assign_release_group
    title = params[:release][:release_group_title].presence
    return unless title

    rg = ReleaseGroup.find_or_initialize_by(title: title)
    if rg.new_record?
      rg.year = params[:release][:release_group_year].presence
      rg.cover_art_url = params[:release][:release_group_cover_art_url].presence
      rg.save!
    end
    @release.release_group = rg
  end

  def assign_primary_artist
    artist_id = params[:release][:primary_artist_id].presence
    return unless artist_id

    @release.release_artists.build(artist_id: artist_id, position: 0) unless @release.release_artists.any? do |ra|
      ra.artist_id == artist_id.to_i
    end
  end
end
