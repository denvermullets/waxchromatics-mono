class IngestReleaseJob < ApplicationJob
  queue_as :default

  def perform(release_discogs_id)
    data = WaxApiClient::ReleaseDetails.call(id: release_discogs_id)
    return if data.blank? || data['id'].blank?

    release = upsert_release(data)
    FetchReleaseCoverArtJob.perform_later(release.id)
    Releases::IngestAssociationsService.call(release: release, data: data)
  end

  private

  def upsert_release(data)
    release_group = find_release_group(data['master_id'])

    find_or_upsert(Release, data['id']) do |r|
      r.assign_attributes(
        title: data['title'] || r.title || 'Unknown',
        released: data['released'],
        country: data['country'],
        notes: data['notes'],
        status: data['status'],
        release_group: release_group
      )
    end
  end

  def find_or_upsert(klass, discogs_id)
    record = klass.find_or_initialize_by(discogs_id: discogs_id)
    yield(record)
    record.save!
    record
  rescue ActiveRecord::RecordNotUnique
    record = klass.find_by!(discogs_id: discogs_id)
    yield(record)
    record.save!
    record
  end

  def find_release_group(master_id)
    return nil if master_id.blank?

    ReleaseGroup.find_by(discogs_id: master_id)
  end
end
