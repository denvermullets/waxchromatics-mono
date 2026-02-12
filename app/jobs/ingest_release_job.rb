class IngestReleaseJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 5
  RETRY_DELAYS = [30, 60, 120, 240, 240].freeze

  def perform(release_discogs_id, attempt: 0)
    data = WaxApiClient::ReleaseDetails.call(id: release_discogs_id)
    return if data.blank? || data['id'].blank?

    release_group = find_release_group(data['master_id'])

    if release_group.nil? && attempt < MAX_ATTEMPTS
      delay = RETRY_DELAYS[attempt]
      self.class.set(wait: delay.seconds).perform_later(release_discogs_id, attempt: attempt + 1)
      return
    end

    release = upsert_release(data, release_group)
    backfill_release_group_year(release)
    FetchReleaseCoverArtJob.perform_later(release.id)
    Releases::IngestAssociationsService.call(release: release, data: data)
  end

  private

  def upsert_release(data, release_group)
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

  def backfill_release_group_year(release)
    rg = release.release_group
    return unless rg
    return if rg.year.present? && rg.year.positive?

    year = parse_year(release.released)
    rg.update_column(:year, year) if year
  end

  def parse_year(released)
    match = released&.match(/\d{4}/)
    return unless match

    value = match.to_s.to_i
    value.positive? ? value : nil
  end

  def find_release_group(master_id)
    master_id = master_id.to_i
    return nil unless master_id.positive?

    ReleaseGroup.find_by(discogs_id: master_id)
  end
end
