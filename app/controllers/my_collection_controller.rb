class MyCollectionController < ApplicationController
  def show
    @tab = params[:tab].presence || 'collection'
    @sort = params[:sort].presence || 'artist'
    @label_filter = params[:label].presence

    load_counts
    scope = filtered_scope(sorted_scope(tab_scope))
    @pagy, @items = pagy(scope, items: 50)
    compute_stats
  end

  EAGER_LOADS = { release: [:release_formats, :artist, { release_labels: :label, release_group: :artists }] }.freeze

  private

  def tab_scope
    case @tab
    when 'collection'
      Current.user.default_collection.collection_items.includes(EAGER_LOADS)
    when 'wantlist'
      Current.user.wantlist_items.includes(EAGER_LOADS)
    when 'trade_list'
      Current.user.trade_list_items.includes(EAGER_LOADS)
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
    return scope if @label_filter.blank?

    scope.joins(release: { release_labels: :label }).where(labels: { name: @label_filter })
  end

  def load_counts
    @collection_count = Current.user.default_collection.collection_items.count
    @wantlist_count = Current.user.wantlist_items.count
    @trade_list_count = Current.user.trade_list_items.count
  end

  def compute_stats
    items = Current.user.default_collection.collection_items
    @total_records = items.count
    @artist_count = items.joins(release: :artist).distinct.count('artists.id')
    load_label_stats(items)
    load_format_stats(items)
  end

  def load_label_stats(items)
    @labels = items.joins(release: { release_labels: :label }).distinct.pluck('labels.name').sort
    @label_count = @labels.size
  end

  def load_format_stats(items)
    formats = items.joins(release: :release_formats).pluck('release_formats.name', 'release_formats.quantity')
    @format_summary = formats.group_by(&:first).transform_values { |pairs| pairs.sum { |_, qty| qty || 1 } }
    @colored_vinyl_count = items.joins(release: :release_formats)
                                .where.not(release_formats: { color: [nil, ''] })
                                .distinct.count
  end
end
