class IngestArtistDiscographyJob < ApplicationJob
  queue_as :default

  PER_PAGE = 100

  def perform(artist_discogs_id, page: 1)
    Artist.where(discogs_id: artist_discogs_id).update_all(discography_ingested: true) if page == 1

    result = WaxApiClient::ArtistDiscography.call(id: artist_discogs_id, page: page, limit: PER_PAGE)
    masters = result[:masters]

    masters.each do |master|
      master_discogs_id = master['id']
      next if master_discogs_id.blank?

      release_group = upsert_release_group(master, master_discogs_id)
      FetchReleaseGroupCoverArtJob.perform_later(release_group.id)
      IngestMasterReleasesJob.perform_later(master_discogs_id)
    end

    # Paginate through remaining pages
    pagy = result[:pagy]
    next_page = pagy['next'] || pagy[:next]
    return unless next_page.present?

    IngestArtistDiscographyJob.perform_later(artist_discogs_id, page: next_page)
  end

  private

  def upsert_release_group(master, discogs_id)
    rg = ReleaseGroup.find_or_initialize_by(discogs_id: discogs_id)
    rg.assign_attributes(
      title: master['title'] || rg.title || 'Unknown',
      year: master['year'],
      main_release_id: master['main_release']
    )
    rg.save!
    rg
  rescue ActiveRecord::RecordNotUnique
    rg = ReleaseGroup.find_by!(discogs_id: discogs_id)
    rg.update!(
      title: master['title'] || rg.title || 'Unknown',
      year: master['year'],
      main_release_id: master['main_release']
    )
    rg
  end
end
