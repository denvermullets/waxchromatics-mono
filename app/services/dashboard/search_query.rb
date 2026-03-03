# frozen_string_literal: true

module Dashboard
  class SearchQuery
    PER_PAGE = 25
    PREFIXES = %w[artist album label cat# barcode credit].freeze

    attr_reader :search_type, :term, :results, :total_count, :total_pages,
                :variant_counts, :collection_counts, :roles_map, :sample_releases

    def initialize(query:, page:, user:)
      @raw_query = query.to_s.strip
      @page = [page.to_i, 1].max
      @user = user
      @search_type, @term = parse_prefix(@raw_query)
      @results = []
      @total_count = 0
      @total_pages = 0
      @variant_counts = {}
      @collection_counts = {}
      @roles_map = {}
      @sample_releases = {}
    end

    def call
      return self if @term.blank?

      send(:"search_#{normalized_type}")
      self
    end

    private

    def parse_prefix(raw)
      match = raw.match(/\A(artist|album|label|cat#|barcode|credit):\s*/i)
      if match
        [match[1].downcase, raw[match[0].length..].strip]
      else
        ['artist', raw.strip]
      end
    end

    def normalized_type
      search_type == 'cat#' ? 'catalog' : search_type
    end

    def offset
      (@page - 1) * PER_PAGE
    end

    def search_artist
      normalized_query = @term.gsub(/\s*\(\d+\)\s*$/, '').strip

      exact_match_sql = <<~SQL.squish
        CASE WHEN REGEXP_REPLACE(artists.name, '\\s*\\(\\d+\\)\\s*$', '') ILIKE ? THEN 0 ELSE 1 END
      SQL

      scope = Artist
              .where('name ILIKE ?', "%#{normalized_query}%")
              .left_joins(:releases)
              .group('artists.id')
              .select(
                'artists.*, COUNT(releases.id) AS release_count, ' \
                'COUNT(DISTINCT releases.release_group_id) AS release_group_count'
              )
              .order(
                Arel.sql(ActiveRecord::Base.sanitize_sql_array([exact_match_sql, normalized_query])),
                Arel.sql('COUNT(releases.id) DESC')
              )

      @total_count = Artist.where('name ILIKE ?', "%#{normalized_query}%").count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @results = scope.offset(offset).limit(PER_PAGE).to_a
    end

    def search_album
      q = "%#{@term}%"

      @total_count = album_total_count(q)
      @total_pages = (@total_count.to_f / PER_PAGE).ceil

      id_rows = album_scope(q).offset(offset).limit(PER_PAGE)
      ids = id_rows.map(&:id)
      @variant_counts = id_rows.to_h { |r| [r.id, r.variant_count.to_i] }
      @collection_counts = Collections::OwnershipQuery.new(@user).by_release_group(ids)
      @results = load_release_groups(ids)
    end

    def album_scope(pattern)
      ReleaseGroup
        .joins(releases: :artist)
        .where('release_groups.title ILIKE ?', pattern)
        .group('release_groups.id')
        .select('release_groups.id, COUNT(DISTINCT releases.id) AS variant_count')
        .order(Arel.sql('COUNT(DISTINCT releases.id) DESC'))
    end

    def album_total_count(pattern)
      ReleaseGroup.joins(releases: :artist).where('release_groups.title ILIKE ?', pattern).distinct.count
    end

    def load_release_groups(ids)
      records = ReleaseGroup
                .where(id: ids)
                .includes(releases: [:artist, :release_formats, { release_labels: :label }])
                .index_by(&:id)
      ids.filter_map { |id| records[id] }
    end

    def search_label
      q = "%#{@term}%"

      @total_count = Label.where('labels.name ILIKE ?', q).count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil

      id_rows = label_scope(q).offset(offset).limit(PER_PAGE)
      ids = id_rows.map(&:id)
      @variant_counts = id_rows.to_h { |r| [r.id, r.release_count.to_i] }

      records = Label.where(id: ids).includes(:parent_label).index_by(&:id)
      @results = ids.filter_map { |id| records[id] }
    end

    def label_scope(pattern)
      Label
        .where('labels.name ILIKE ?', pattern)
        .left_joins(:releases)
        .group('labels.id')
        .select('labels.id, COUNT(DISTINCT releases.id) AS release_count')
        .order(Arel.sql('COUNT(DISTINCT releases.id) DESC'))
    end

    def search_catalog
      q = "%#{@term}%"

      @total_count = ReleaseLabel.where('catalog_number ILIKE ?', q).count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil

      @results = ReleaseLabel
                 .where('catalog_number ILIKE ?', q)
                 .includes(release: [:artist, :release_formats, { release_labels: :label }])
                 .joins(:release)
                 .order(:catalog_number)
                 .offset(offset)
                 .limit(PER_PAGE)
                 .to_a
    end

    def search_barcode
      q = "%#{@term}%"

      @total_count = ReleaseIdentifier
                     .where(identifier_type: 'Barcode')
                     .where('value ILIKE ?', q)
                     .count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil

      @results = ReleaseIdentifier
                 .where(identifier_type: 'Barcode')
                 .where('value ILIKE ?', q)
                 .includes(release: [:artist, :release_formats, { release_labels: :label }])
                 .joins(:release)
                 .order(:value)
                 .offset(offset)
                 .limit(PER_PAGE)
                 .to_a
    end

    def search_credit
      credit = Dashboard::CreditSearch.new(term: @term, page: @page, per_page: PER_PAGE).call
      @results = credit.results
      @total_count = credit.total_count
      @total_pages = credit.total_pages
      @variant_counts = credit.variant_counts
      @roles_map = credit.roles_map
      @sample_releases = credit.sample_releases
    end
  end
end
