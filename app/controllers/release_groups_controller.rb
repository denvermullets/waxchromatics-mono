class ReleaseGroupsController < ApplicationController
  def search
    release_groups = ReleaseGroup.where('title ILIKE ?', "%#{params[:q]}%")
                                 .order(:title).limit(10)
    render json: release_groups.map { |rg|
      { id: rg.id, title: rg.title, year: rg.year, cover_art_url: rg.cover_art_url }
    }
  end

  def show
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
end
