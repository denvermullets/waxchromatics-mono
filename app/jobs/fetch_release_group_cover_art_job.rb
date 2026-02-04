class FetchReleaseGroupCoverArtJob < ApplicationJob
  queue_as :music_brainz

  def perform(release_group_id)
    release_group = ReleaseGroup.find(release_group_id)
    log_start(release_group)

    return log_skip(release_group_id) if already_complete?(release_group)

    mbid = resolve_mbid(release_group)
    return log_no_mbid(release_group) if mbid.blank?

    persist_mbid(release_group, mbid)
    sleep(1.2)
    fetch_and_save_cover_art(release_group, mbid)
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn(
      "[FetchReleaseGroupCoverArt] Duplicate MBID #{mbid} " \
      "for ReleaseGroup##{release_group_id} — skipping"
    )
  end

  private

  def log_start(release_group)
    Rails.logger.info(
      "[FetchReleaseGroupCoverArt] Starting for ReleaseGroup##{release_group.id} " \
      "\"#{release_group.title}\" (discogs_id=#{release_group.discogs_id})"
    )
  end

  def log_skip(release_group_id)
    Rails.logger.info(
      "[FetchReleaseGroupCoverArt] Skipping ReleaseGroup##{release_group_id} " \
      '— already has MBID and cover art'
    )
  end

  def log_no_mbid(release_group)
    Rails.logger.warn(
      "[FetchReleaseGroupCoverArt] No MBID found for ReleaseGroup##{release_group.id} " \
      "(discogs_id=#{release_group.discogs_id})"
    )
  end

  def already_complete?(release_group)
    release_group.musicbrainz_id.present? && release_group.cover_art_url.present?
  end

  def artist_name_for(release_group)
    first_release = release_group.releases.first
    first_artist = first_release&.artists&.first
    first_artist&.name
  end

  def resolve_mbid(release_group)
    artist_name = artist_name_for(release_group)
    Rails.logger.info(
      "[FetchReleaseGroupCoverArt] Looking up MBID for \"#{release_group.title}\" " \
      "by \"#{artist_name}\" (discogs_id=#{release_group.discogs_id})"
    )

    release_group.musicbrainz_id.presence ||
      MusicBrainzClient::ReleaseGroupLookup.call(
        discogs_master_id: release_group.discogs_id,
        artist_name: artist_name,
        title: release_group.title
      )
  end

  def persist_mbid(release_group, mbid)
    return if release_group.musicbrainz_id.present?

    release_group.update!(musicbrainz_id: mbid)
    Rails.logger.info(
      "[FetchReleaseGroupCoverArt] Saved MBID #{mbid} for ReleaseGroup##{release_group.id}"
    )
  end

  def fetch_and_save_cover_art(release_group, mbid)
    Rails.logger.info(
      '[FetchReleaseGroupCoverArt] Fetching cover art for ' \
      "\"#{release_group.title}\" (mbid=#{mbid})"
    )
    cover_url = CoverArtClient::ReleaseGroupCover.call(musicbrainz_id: mbid)

    if cover_url.present?
      release_group.update!(cover_art_url: cover_url)
      Rails.logger.info(
        "[FetchReleaseGroupCoverArt] Saved cover art for ReleaseGroup##{release_group.id}"
      )
    else
      Rails.logger.warn(
        '[FetchReleaseGroupCoverArt] No cover art found ' \
        "for ReleaseGroup##{release_group.id} (mbid=#{mbid})"
      )
    end
  end
end
