class IngestMasterReleasesJob < ApplicationJob
  queue_as :default

  def perform(master_discogs_id, page: 1)
    result = WaxApiClient::MasterReleasesVinyl.call(
      id: master_discogs_id,
      page: page
    )

    result[:releases].each do |release_data|
      release_id = release_data['id']
      next if release_id.blank?

      IngestReleaseJob.perform_later(release_id)
    end

    pagy = result[:pagy]
    next_page = pagy['next'] || pagy[:next]
    return unless next_page.present?

    IngestMasterReleasesJob.perform_later(master_discogs_id, page: next_page)
  end
end
