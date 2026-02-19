# frozen_string_literal: true

module Artists
  class ShowQuery
    RELEASE_TYPE_ORDER = ArtistsController::RELEASE_TYPE_ORDER

    attr_reader :artist, :tab, :has_appearances, :sections, :appearances, :collection_counts, :local_releases

    def initialize(artist:, tab:, user:, paginate:)
      @artist = artist
      @tab = tab
      @user = user
      @paginate = paginate
      @has_appearances = artist_has_appearances?
    end

    def call
      rg_ids = load_tab_data
      @local_releases = @artist&.releases || Release.none
      @collection_counts = Collections::OwnershipQuery.new(@user).by_release_group(rg_ids)
      self
    end

    private

    def load_tab_data
      if @tab == 'appearances' && @has_appearances
        load_appearances
        @appearances.flat_map { |a| a[:release_groups].map(&:id) }
      else
        @tab = 'discography'
        load_discography
        @sections.flat_map { |s| s[:release_groups].map(&:id) }
      end
    end

    def artist_has_appearances?
      return false unless @artist

      @artist.release_contributors.where.not(role: [nil, '']).exists?
    end

    def load_discography
      @sections = RELEASE_TYPE_ORDER.filter_map do |type|
        groups = @artist&.release_groups
        scope = groups ? groups.where(release_type: type).order(:year) : ReleaseGroup.none
        next if scope.none?

        pagy_obj, records = @paginate.call(scope)
        { type: type, pagy: pagy_obj, release_groups: records }
      end
    end

    def load_appearances
      @appearances = []
      return unless @artist

      rg_ids_by_role = appearance_rg_ids_by_role
      return if rg_ids_by_role.empty?

      @appearances = build_appearances(rg_ids_by_role)
    end

    def appearance_rg_ids_by_role
      @artist.release_contributors
             .where.not(role: [nil, ''])
             .joins(release: :release_group)
             .select('release_contributors.role, release_groups.id AS release_group_id')
             .distinct
             .each_with_object({}) { |rc, hash| (hash[rc.role] ||= Set.new) << rc.release_group_id }
    end

    def build_appearances(rg_ids_by_role)
      all_rg_ids = rg_ids_by_role.values.reduce(:+).to_a
      rg_lookup = ReleaseGroup.where(id: all_rg_ids).includes(releases: :artist).index_by(&:id)

      rg_ids_by_role.sort_by { |role, _| role.downcase }.filter_map do |role, rg_ids|
        rgs = rg_ids.filter_map { |id| rg_lookup[id] }.sort_by { |rg| rg.year || 0 }
        { role: role, release_groups: rgs } if rgs.any?
      end
    end
  end
end
