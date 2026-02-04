class FetchReleaseCoverArtJob < ApplicationJob
  queue_as :music_brainz

  def perform(release_id)
    release = Release.find(release_id)
    log_start(release)

    return log_skip(release_id) if already_complete?(release)

    mbid = resolve_mbid(release)
    return log_no_mbid(release) if mbid.blank?

    persist_mbid(release, mbid)
    sleep(1.2)
    fetch_and_save_cover_art(release, mbid)
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn(
      "[FetchReleaseCoverArt] Duplicate MBID #{mbid} for Release##{release_id} — skipping"
    )
  end

  private

  def log_start(release)
    Rails.logger.info(
      "[FetchReleaseCoverArt] Starting for Release##{release.id} " \
      "\"#{release.title}\" (discogs_id=#{release.discogs_id})"
    )
  end

  def log_skip(release_id)
    Rails.logger.info(
      "[FetchReleaseCoverArt] Skipping Release##{release_id} — already has MBID and cover art"
    )
  end

  def log_no_mbid(release)
    Rails.logger.warn(
      "[FetchReleaseCoverArt] No MBID found for Release##{release.id} " \
      "(discogs_id=#{release.discogs_id})"
    )
  end

  def already_complete?(release)
    release.musicbrainz_id.present? && release.cover_art_url.present?
  end

  def resolve_mbid(release)
    artist_name = release.artists.first&.name
    Rails.logger.info(
      "[FetchReleaseCoverArt] Looking up MBID for \"#{release.title}\" " \
      "by \"#{artist_name}\" (discogs_id=#{release.discogs_id})"
    )

    release.musicbrainz_id.presence ||
      MusicBrainzClient::ReleaseLookup.call(
        discogs_release_id: release.discogs_id,
        artist_name: artist_name,
        title: release.title
      )
  end

  def persist_mbid(release, mbid)
    return if release.musicbrainz_id.present?

    release.update!(musicbrainz_id: mbid)
    Rails.logger.info("[FetchReleaseCoverArt] Saved MBID #{mbid} for Release##{release.id}")
  end

  def fetch_and_save_cover_art(release, mbid)
    Rails.logger.info(
      "[FetchReleaseCoverArt] Fetching cover art for \"#{release.title}\" (mbid=#{mbid})"
    )
    cover_url = CoverArtClient::ReleaseCover.call(musicbrainz_id: mbid)

    if cover_url.present?
      release.update!(cover_art_url: cover_url)
      Rails.logger.info("[FetchReleaseCoverArt] Saved cover art for Release##{release.id}")
    else
      Rails.logger.warn(
        "[FetchReleaseCoverArt] No cover art found for Release##{release.id} (mbid=#{mbid})"
      )
    end
  end
end
