class IngestCreditedArtistDiscographyJob < ApplicationJob
  queue_as :default

  def perform(artist_discogs_id)
    artist = Artist.find_by(discogs_id: artist_discogs_id)
    return unless artist
    return if artist.discography_ingested?

    enrich_artist_profile(artist, artist_discogs_id)
    artist.update!(discography_ingested: true)

    IngestArtistDiscographyJob.perform_later(artist_discogs_id)
  end

  private

  def enrich_artist_profile(artist, discogs_id)
    details = WaxApiClient::ArtistDetails.call(id: discogs_id)
    return if details.blank?

    attrs = extract_artist_attrs(details)
    artist.update!(attrs) if attrs.present?
  end

  def extract_artist_attrs(details)
    attrs = {}
    attrs[:name] = details['name'] if details['name'].present?
    if details.key?('realname') || details.key?('real_name')
      attrs[:real_name] =
        details['realname'] || details['real_name']
    end
    attrs[:profile] = details['profile'] if details.key?('profile')
    attrs
  end
end
