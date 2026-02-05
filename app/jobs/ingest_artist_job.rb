class IngestArtistJob < ApplicationJob
  queue_as :default

  def perform(artist_data)
    discogs_id = artist_data['id']
    return if discogs_id.blank?

    artist = upsert_artist(artist_data, discogs_id)

    # Mark as ingested on external API
    WaxApiClient::MarkArtistIngested.call(discogs_id: discogs_id)

    # Update pending status
    pending = PendingIngest.find_by(discogs_id: discogs_id, resource_type: 'Artist')
    pending&.update!(status: 'completed')

    # Broadcast Turbo Stream update
    broadcast_completion(discogs_id, artist)

    IngestArtistDiscographyJob.perform_later(discogs_id)
  end

  private

  def upsert_artist(artist_data, discogs_id)
    artist = Artist.find_or_initialize_by(discogs_id: discogs_id)
    artist.assign_attributes(artist_attributes(artist_data, artist))
    artist.save!
    artist
  rescue ActiveRecord::RecordNotUnique
    artist = Artist.find_by!(discogs_id: discogs_id)
    artist.update!(artist_attributes(artist_data, artist))
    artist
  end

  def artist_attributes(artist_data, artist)
    {
      name: artist_data['name'] || artist.name || 'Unknown',
      real_name: artist_data['realname'] || artist_data['real_name'],
      profile: artist_data['profile']
    }
  end

  def broadcast_completion(discogs_id, artist)
    Turbo::StreamsChannel.broadcast_replace_to(
      'search_updates',
      target: "external-artist-#{discogs_id}",
      partial: 'dashboard/artist_row_local',
      locals: { artist: artist }
    )
  end
end
