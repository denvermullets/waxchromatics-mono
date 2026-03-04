class ReclassifyReleaseGroupsJob < ApplicationJob
  queue_as :reclassify

  BATCH_SIZE = 1000

  def perform(offset = 0)
    batch = ReleaseGroup
            .where(release_type: 'Unofficial Release')
            .order(:id)
            .offset(offset)
            .limit(BATCH_SIZE)
            .to_a

    return if batch.empty?

    batch.each { |release_group| reclassify(release_group) }

    ReclassifyReleaseGroupsJob.perform_later(offset + BATCH_SIZE) if batch.size == BATCH_SIZE
  end

  private

  def reclassify(release_group)
    descriptions = release_group.releases
                                .joins(:release_formats)
                                .pluck('release_formats.descriptions')
                                .compact

    keywords = descriptions.flat_map { |d| d.split('; ') }
    types = keywords.filter_map { |kw| classify_keyword(kw) }.uniq
    return if types.empty?

    new_type = Releases::IngestAssociationsService::TYPE_PRIORITY.find { |t| types.include?(t) } || 'Album'
    release_group.update_column(:release_type, new_type) if new_type != 'Unofficial Release'
  end

  def classify_keyword(keyword)
    case keyword
    when 'Unofficial Release' then 'Unofficial Release'
    when 'Compilation' then 'Compilation'
    when /\bEP\b/, 'Mini-Album' then 'EP'
    when 'Single', 'Maxi-Single' then 'Single'
    when 'Album', 'LP' then 'Album'
    end
  end
end
