class ReleasesController < ApplicationController
  def index
    @releases = Release.includes(:release_group, release_artists: :artist).order(created_at: :desc)
  end

  def new
    @release = Release.new
  end

  def create
    @release = Release.new(release_params)
    assign_release_group
    if @release.save
      redirect_to artist_release_group_release_path(@release.artists.first, @release.release_group, @release),
                  notice: 'Release created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @release = Release.includes(
      :release_formats, :tracks,
      release_labels: :label,
      release_artists: :artist,
      release_group: :releases
    ).find(params[:id])
    @artists = @release.artists
    @release_group = @release.release_group
    @tracklist = @release.tracks.order(:sequence)
    @formats = @release.release_formats
    @labels = @release.release_labels.includes(:label)
  end

  private

  def release_params
    params.require(:release).permit(:title, :released, :country, :notes, :status)
  end

  def assign_release_group
    title = params[:release][:release_group_title].presence
    return unless title

    @release.release_group = ReleaseGroup.find_or_create_by!(title: title)
  end
end
