class ImportCollectionRowJob < ApplicationJob
  queue_as :default

  CONDITION_MAP = {
    'Mint (M)' => 'M',
    'Near Mint (NM or M-)' => 'NM',
    'Very Good Plus (VG+)' => 'VG+',
    'Very Good (VG)' => 'VG',
    'Good Plus (G+)' => 'G+',
    'Good (G)' => 'G',
    'Fair (F)' => 'F',
    'Poor (P)' => 'P'
  }.freeze

  MAX_ATTEMPTS = 5
  RETRY_DELAYS = [30, 60, 120, 240].freeze # seconds, indexed by attempt-1

  def perform(collection_import_row_id, attempt = 0)
    row = CollectionImportRow.find(collection_import_row_id)
    import = row.collection_import

    if attempt.zero?
      handle_first_attempt(row, import)
    else
      handle_retry_attempt(row, import, attempt)
    end
  end

  private

  def handle_first_attempt(row, import)
    release = find_local_release(row)

    if release
      add_to_collection(row, release, import)
      return
    end

    data = WaxApiClient::ReleaseDetails.call(id: row.discogs_release_id)

    if data.blank? || data['id'].blank?
      mark_failed(row, import, "Release not found on Discogs (ID: #{row.discogs_release_id})")
      return
    end

    enqueue_ingestion(row, data)
    row.update!(status: 'ingesting')
    ImportCollectionRowJob.set(wait: RETRY_DELAYS[0].seconds).perform_later(row.id, 1)
  end

  def handle_retry_attempt(row, import, attempt)
    release = Release.find_by(discogs_id: row.discogs_release_id)

    if release
      add_to_collection(row, release, import)
    elsif attempt < MAX_ATTEMPTS
      delay = RETRY_DELAYS.fetch(attempt - 1, RETRY_DELAYS.last)
      ImportCollectionRowJob.set(wait: delay.seconds).perform_later(row.id, attempt + 1)
    else
      mark_failed(row, import, 'Release ingestion did not complete')
    end
  end

  def find_local_release(row)
    release = Release.find_by(discogs_id: row.discogs_release_id) if row.discogs_release_id.present?
    return release if release

    return nil if row.artist_name.blank? || row.title.blank?

    scope = Release.joins(:artist).where(artists: { name: row.artist_name }, title: row.title)
    if row.catalog_number.present?
      scope = scope.joins(:release_labels).where(release_labels: { catalog_number: row.catalog_number })
    end
    scope.first
  end

  def add_to_collection(row, release, import)
    user = import.user
    collection = user.default_collection
    condition = map_condition(row.media_condition)

    PaperTrail.request(whodunnit: user.id.to_s, controller_info: { collection_import_id: import.id }) do
      collection.collection_items.create!(release: release, condition: condition)
    end

    row.update!(status: 'completed', release: release)
    import.increment!(:completed_rows)
    check_import_completion(import)
  end

  def mark_failed(row, import, message)
    row.update!(status: 'failed', error_message: message)
    import.increment!(:failed_rows)
    check_import_completion(import)
  end

  def enqueue_ingestion(row, data)
    release_artists = data['release_artists'] || []
    primary_artist = release_artists.find { |a| a['extra'].zero? } || release_artists.first

    if primary_artist
      IngestArtistJob.perform_later(
        { 'id' => primary_artist['artist_id'], 'name' => primary_artist['artist_name'] }
      )
    else
      mark_failed(row, row.collection_import, "No artist data for release #{row.discogs_release_id}")
    end
  end

  def check_import_completion(import)
    remaining = import.collection_import_rows.where(status: %w[pending ingesting]).count
    import.update!(status: 'completed') if remaining.zero?
  end

  def map_condition(discogs_condition)
    CONDITION_MAP.fetch(discogs_condition.to_s.strip, 'NM')
  end
end
