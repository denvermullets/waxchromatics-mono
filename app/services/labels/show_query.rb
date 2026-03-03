# frozen_string_literal: true

module Labels
  class ShowQuery
    RELEASE_TYPE_ORDER = ArtistsController::RELEASE_TYPE_ORDER

    attr_reader :label, :parent_label, :sub_labels, :release_count,
                :sections, :collection_counts

    def initialize(label:, user:, paginate:)
      @label = label
      @user = user
      @paginate = paginate
    end

    def call
      @parent_label = @label.parent_label
      @sub_labels = @label.sub_labels.order(:name)
      @release_count = @label.releases.distinct.count

      rg_ids = load_sections
      @collection_counts = Collections::OwnershipQuery.new(@user).by_release_group(rg_ids)
      self
    end

    private

    def load_sections
      base_rg_ids = Release.joins(:release_labels)
                           .where(release_labels: { label_id: @label.id })
                           .select(:release_group_id)

      @sections = RELEASE_TYPE_ORDER.filter_map do |type|
        scope = ReleaseGroup.where(id: base_rg_ids)
                            .where(release_type: type)
                            .includes(releases: :artist)
                            .order(:year)
        next if scope.none?

        pagy_obj, records = @paginate.call(scope)
        { type: type, pagy: pagy_obj, release_groups: records }
      end

      @sections.flat_map { |s| s[:release_groups].map(&:id) }
    end
  end
end
