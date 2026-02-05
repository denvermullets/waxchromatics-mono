module Releases
  class IngestAssociationsService < Service
    def initialize(release:, data:)
      @release = release
      @data = data
    end

    def call
      create_tracks
      create_release_artists
      create_release_labels
      create_release_formats
      create_release_identifiers
    end

    private

    attr_reader :release, :data

    def create_tracks
      tracks_data = data['release_tracks'] || []
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

    def create_release_artists
      artists_data = data['release_artists'] || []
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

    def create_release_labels
      labels_data = data['release_labels'] || []
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

    def create_release_formats
      formats_data = data['release_formats'] || []
      formats_data.each_with_index do |format_data, index|
        existing = release.release_formats.offset(index).first
        format_record = existing || release.release_formats.build

        format_record.update!(
          name: format_data['name'],
          quantity: format_data['qty']&.to_i,
          descriptions: format_data['descriptions'],
          color: format_data['text_string']
        )
      end
    end

    def create_release_identifiers
      identifiers_data = data['release_identifiers'] || []
      identifiers_data.each do |identifier_data|
        discogs_id = identifier_data['id']
        next if discogs_id.blank?

        identifier = ReleaseIdentifier.find_or_initialize_by(discogs_id: discogs_id)
        identifier.update!(
          release: release,
          identifier_type: identifier_data['type'],
          value: identifier_data['value'],
          description: identifier_data['description']
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
  end
end
