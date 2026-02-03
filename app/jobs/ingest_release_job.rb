class IngestReleaseJob < ApplicationJob
  queue_as :default

  def perform(release_discogs_id)
    data = WaxApiClient::ReleaseDetails.call(id: release_discogs_id)
    return if data.blank? || data['id'].blank?

    release = upsert_release(data)
    create_tracks(release, data['release_tracks'] || [])
    create_release_artists(release, data['release_artists'] || [])
    create_release_labels(release, data['release_labels'] || [])
    create_release_formats(release, data['release_formats'] || [])
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

  def create_tracks(release, tracks_data)
    tracks_data.each do |track_data|
      sequence = track_data['sequence']
      next if sequence.blank?

      track = release.tracks.find_or_initialize_by(sequence: sequence)
      track.update!(
        title: track_data['title'],
        position: track_data['position'],
        duration: track_data['duration']
      )
    end
  end

  def create_release_artists(release, artists_data)
    artists_data.each do |artist_data|
      artist_discogs_id = artist_data['artist_id']
      next if artist_discogs_id.blank?

      artist = find_or_upsert(Artist, artist_discogs_id) do |a|
        a.name = artist_data['artist_name'] || a.name || 'Unknown'
      end

      ra = release.release_artists.find_or_initialize_by(artist: artist)
      ra.update!(
        position: artist_data['position'],
        role: artist_data['role'].presence
      )
    end
  end

  def create_release_labels(release, labels_data)
    labels_data.each do |label_data|
      label_discogs_id = label_data['label_id']
      next if label_discogs_id.blank?

      label = find_or_upsert(Label, label_discogs_id) do |l|
        l.name = label_data['label_name'] || l.name || 'Unknown'
      end

      rl = release.release_labels.find_or_initialize_by(label: label)
      rl.update!(catalog_number: label_data['catno'])
    end
  end

  def create_release_formats(release, formats_data)
    formats_data.each_with_index do |format_data, index|
      existing = release.release_formats.offset(index).first
      format_record = existing || release.release_formats.build

      format_record.update!(
        name: format_data['name'],
        quantity: format_data['qty']&.to_i,
        descriptions: format_data['descriptions']
      )
    end
  end
end
