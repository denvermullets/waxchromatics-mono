class IngestArtistJob < ApplicationJob
  queue_as :default

  def perform(artist_data)
    discogs_id = artist_data['id']
    return if discogs_id.blank?

    upsert_artist(artist_data, discogs_id)
    IngestArtistDiscographyJob.perform_later(discogs_id)
  end

  private

  def upsert_artist(artist_data, discogs_id)
    artist = Artist.find_or_initialize_by(discogs_id: discogs_id)
    artist.assign_attributes(artist_attributes(artist_data, artist))
    artist.save!
  rescue ActiveRecord::RecordNotUnique
    artist = Artist.find_by!(discogs_id: discogs_id)
    artist.update!(artist_attributes(artist_data, artist))
  end

  def artist_attributes(artist_data, artist)
    {
      name: artist_data['name'] || artist.name || 'Unknown',
      real_name: artist_data['realname'] || artist_data['real_name'],
      profile: artist_data['profile']
    }
  end
end
