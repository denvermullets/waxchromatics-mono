class CollectionController < ApplicationController
  def show
    set_filters
    load_counts

    if @tab == 'history'
      load_history
    else
      scope = filtered_scope(sorted_scope(tab_scope))
      @pagy, @items = pagy(scope, items: 50)
      compute_stats
    end
  end

  EAGER_LOADS = { release: [:release_formats, :artist, { release_labels: :label, release_group: :artists }] }.freeze

  private

  def set_filters
    @user = User.find_by!(username: params[:username])
    @tab = params[:tab].presence || 'collection'
    @sort = params[:sort].presence || 'artist'
    @view = params[:view].presence || (@user.setting.collection_list_view ? 'list' : 'grid')
    @label_filter = params[:label].presence
  end

  def tab_scope
    case @tab
    when 'collection'
      @user.default_collection.collection_items.includes(EAGER_LOADS)
    when 'wantlist'
      @user.wantlist_items.includes(EAGER_LOADS)
    when 'trade_list'
      @user.trade_list_items.includes(EAGER_LOADS)
    end
  end

  def sorted_scope(scope)
    case @sort
    when 'artist'
      scope.joins(release: :artist)
           .order('artists.name ASC, releases.title ASC')
    when 'title'  then scope.joins(:release).order('releases.title ASC')
    when 'year'   then scope.joins(:release).order('releases.released DESC')
    when 'label'  then scope.joins(release: { release_labels: :label }).order('labels.name ASC')
    when 'added'  then scope.order(created_at: :desc)
    end
  end

  def filtered_scope(scope)
    if @label_filter.present?
      scope = scope.joins(release: { release_labels: :label }).where(labels: { name: @label_filter })
    end

    if params[:q].present?
      term = "%#{params[:q]}%"
      scope = scope.joins(release: :artist)
                   .where('artists.name ILIKE :q OR releases.title ILIKE :q', q: term)
    end

    scope
  end

  def load_counts
    @collection_count = @user.default_collection.collection_items.count
    @wantlist_count = @user.wantlist_items.count
    @trade_list_count = @user.trade_list_items.count
  end

  def compute_stats
    items = @user.default_collection.collection_items
    @total_records = items.count
    @artist_count = items.joins(release: :artist).distinct.count('artists.id')
    load_label_stats(items)
    load_format_stats(items)
  end

  def load_label_stats(items)
    label_counts = items.joins(release: { release_labels: :label })
                        .group('labels.name')
                        .order(Arel.sql('COUNT(*) DESC'))
                        .count
    @labels = label_counts.keys
    @label_count = @labels.size
  end

  def load_format_stats(items)
    formats = items.joins(release: :release_formats).pluck('release_formats.name', 'release_formats.quantity')
    @format_summary = formats.group_by(&:first).transform_values { |pairs| pairs.sum { |_, qty| qty || 1 } }
    @colored_vinyl_count = items.joins(release: :release_formats)
                                .where.not(release_formats: { color: [nil, ''] })
                                .distinct.count
  end

  def load_history
    versions = PaperTrail::Version
               .where(item_type: %w[CollectionItem WantlistItem TradeListItem], whodunnit: @user.id.to_s)
               .order(created_at: :desc)

    @pagy, @versions = pagy(versions, items: 30)

    release_ids = @versions.filter_map(&:release_id).uniq
    @releases_by_id = Release.where(id: release_ids)
                             .includes(:artist, :release_formats, :release_group, release_labels: :label)
                             .index_by(&:id)

    import_ids = @versions.filter_map(&:collection_import_id).uniq
    @imports_by_id = CollectionImport.where(id: import_ids).index_by(&:id) if import_ids.any?
    @load_history ||= {}
  end
end
