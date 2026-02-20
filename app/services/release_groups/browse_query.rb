# frozen_string_literal: true

module ReleaseGroups
  class BrowseQuery
    FIRST_ALPHA_SQL = "UPPER(SUBSTRING(artists.name FROM '[A-Za-z]'))"

    attr_reader :pagy, :release_groups, :variant_counts, :grouped, :available_letters

    def initialize(params:, filters:, sort:, page:, limit:)
      @params = params
      @filters = filters
      @sort = sort
      @page = page
      @limit = limit
    end

    def call
      scope = build_filtered_scope
      @available_letters = extract_available_letters(scope)
      sorted = apply_sort(scope)
      @pagy, id_rows = paginate(sorted)
      hydrate(id_rows)
      self
    end

    private

    def build_filtered_scope
      scope = base_scope
      scope = apply_search(scope)
      scope = apply_letter_filter(scope)
      scope = apply_format_filter(scope)
      scope = apply_decade_filter(scope)
      scope = apply_label_filter(scope)
      scope = apply_genre_filter(scope)
      scope = apply_country_filter(scope)
      apply_colored_filter(scope)
    end

    def base_scope
      ReleaseGroup
        .joins(releases: :artist)
        .where.not(releases: { artist_id: nil })
        .group('release_groups.id')
        .select('release_groups.id, COUNT(releases.id) AS variant_count, MIN(artists.name) AS primary_artist_name')
    end

    def apply_search(scope)
      return scope unless @params[:q].present?

      q = "%#{@params[:q]}%"
      scope.where('artists.name ILIKE :q OR release_groups.title ILIKE :q', q: q)
    end

    def apply_letter_filter(scope)
      return scope unless @filters[:letter].present?

      scope.having("UPPER(SUBSTRING(MIN(artists.name) FROM '[A-Za-z]')) = ?", @filters[:letter])
    end

    def apply_format_filter(scope)
      return scope unless @filters[:format].present?

      scope.joins('INNER JOIN release_formats ON release_formats.release_id = releases.id')
           .where(release_formats: { name: @filters[:format] })
    end

    def apply_decade_filter(scope)
      return scope unless @filters[:decade].present?

      decade_start = @filters[:decade].to_i
      scope.where('release_groups.year BETWEEN ? AND ?', decade_start, decade_start + 9)
    end

    def apply_label_filter(scope)
      return scope unless @filters[:label].present?

      scope.joins('INNER JOIN release_labels ON release_labels.release_id = releases.id')
           .joins('INNER JOIN labels ON labels.id = release_labels.label_id')
           .where(labels: { name: @filters[:label] })
    end

    def apply_genre_filter(scope)
      return scope unless @filters[:genre].present?

      scope.joins('INNER JOIN release_genres ON release_genres.release_id = releases.id')
           .where(release_genres: { genre: @filters[:genre] })
    end

    def apply_country_filter(scope)
      return scope unless @filters[:country].present?

      scope.where(releases: { country: @filters[:country] })
    end

    def apply_colored_filter(scope)
      return scope unless @filters[:colored]

      scope.joins('INNER JOIN release_formats rf_color ON rf_color.release_id = releases.id')
           .where.not(rf_color: { color: [nil, ''] })
    end

    def apply_sort(scope)
      case @sort
      when 'artist_za'  then scope.order(Arel.sql('MIN(artists.name) DESC, release_groups.title ASC'))
      when 'title_az'   then scope.order('release_groups.title ASC')
      when 'newest'     then scope.order('release_groups.year DESC NULLS LAST, release_groups.title ASC')
      when 'oldest'     then scope.order('release_groups.year ASC NULLS LAST, release_groups.title ASC')
      when 'most_variants'   then scope.order(Arel.sql('COUNT(releases.id) DESC, release_groups.title ASC'))
      when 'recently_added'  then scope.order('release_groups.created_at DESC')
      else scope.order(Arel.sql('MIN(artists.name) ASC, release_groups.title ASC'))
      end
    end

    def paginate(scope)
      # .count on a grouped scope returns a hash; use a subquery to get the scalar count
      count = ReleaseGroup.from(scope, :sub).count
      pagy = Pagy::Offset.new(count: count, page: @page, limit: @limit)
      rows = scope.offset(pagy.offset).limit(@limit).map do |row|
        { 'id' => row.id, 'variant_count' => row.variant_count, 'primary_artist_name' => row.primary_artist_name }
      end
      [pagy, rows]
    end

    def extract_available_letters(scope)
      # Use the filtered scope (minus grouping) to find letters present in current result set
      scope.pluck(Arel.sql("UPPER(SUBSTRING(MIN(artists.name) FROM '[A-Za-z]'))")).compact.uniq.sort
    end

    def hydrate(id_rows)
      ids = id_rows.map { |r| r['id'] }
      @variant_counts = id_rows.each_with_object({}) { |r, h| h[r['id']] = r['variant_count'].to_i }

      records = ReleaseGroup.where(id: ids)
                            .includes(releases: [:release_formats, :artist, { release_labels: :label }])
                            .index_by(&:id)
      @release_groups = ids.filter_map { |id| records[id] }

      build_alpha_groups(id_rows) if alphabetical_sort?
    end

    def build_alpha_groups(id_rows)
      artist_names = id_rows.each_with_object({}) { |r, h| h[r['id']] = r['primary_artist_name'] }

      @grouped = @release_groups.group_by do |rg|
        first_letter(artist_names[rg.id])
      end
    end

    def alphabetical_sort?
      %w[artist_az artist_za].include?(@sort)
    end

    def first_letter(name)
      char = name&.match(/[A-Za-z]/)&.to_s
      char&.upcase || '#'
    end
  end
end
