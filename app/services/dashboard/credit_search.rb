# frozen_string_literal: true

module Dashboard
  class CreditSearch
    attr_reader :results, :total_count, :total_pages, :variant_counts, :roles_map, :sample_releases

    def initialize(term:, page:, per_page:)
      @term = term
      @page = page
      @per_page = per_page
    end

    def call
      pattern = "%#{@term}%"

      @total_count = count_total(pattern)
      @total_pages = (@total_count.to_f / @per_page).ceil

      artists = scope(pattern).offset(offset).limit(@per_page).to_a
      ids = artists.map(&:id)
      @variant_counts = artists.to_h { |a| [a.id, a.appearance_count.to_i] }
      @roles_map = build_roles_map(ids)
      @sample_releases = build_sample_releases(ids)
      @results = artists
      self
    end

    private

    def offset
      (@page - 1) * @per_page
    end

    def scope(pattern)
      Artist
        .joins(:release_contributors)
        .where('artists.name ILIKE ?', pattern)
        .group('artists.id')
        .select('artists.*, COUNT(DISTINCT release_contributors.release_id) AS appearance_count')
        .order(Arel.sql('COUNT(DISTINCT release_contributors.release_id) DESC'))
    end

    def count_total(pattern)
      Artist.joins(:release_contributors).where('artists.name ILIKE ?', pattern).distinct.count
    end

    def build_roles_map(ids)
      ReleaseContributor
        .where(artist_id: ids)
        .select(:artist_id, :role)
        .distinct
        .group_by(&:artist_id)
        .transform_values { |contribs| contribs.map(&:role).compact.uniq }
    end

    def build_sample_releases(ids)
      ReleaseContributor
        .where(artist_id: ids)
        .includes(release: :artist)
        .group_by(&:artist_id)
        .transform_values { |contribs| contribs.map(&:release).uniq(&:id).first(3) }
    end
  end
end
