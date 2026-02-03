class ReleaseGroupsController < ApplicationController
  def show
    @release_group = ReleaseGroup.find(params[:id])
    @releases = @release_group.releases
                              .includes(:release_formats, :tracks, release_labels: :label, release_artists: :artist)
                              .order(:released)
    @artists = @releases.flat_map(&:artists).uniq
    main_release = @releases.find { |r| r.discogs_id == @release_group.main_release_id } || @releases.first
    @main_release = main_release
    @tracklist = main_release&.tracks&.order(:sequence) || Track.none
  end
end
