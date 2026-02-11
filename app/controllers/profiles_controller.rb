class ProfilesController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    @user = User.find_by!(username: params[:username])
    @own_profile = Current.user == @user

    items = @user.default_collection.collection_items
    @total_records = items.count
    return if @total_records.zero?

    load_stats(items)
    load_charts(items)
  end

  private

  def load_stats(items)
    @artist_count = items.joins(release: :artist).distinct.count('artists.id')
    @label_count = items.joins(release: { release_labels: :label }).distinct.count('labels.id')
    @wantlist_count = @user.wantlist_items.count
    @trade_list_count = @user.trade_list_items.count
  end

  def load_charts(items)
    load_format_chart(items)
    load_condition_chart(items)
    load_top_labels(items)
    load_top_artists(items)
    load_decade_chart(items)
    load_size_chart(items)
    load_color_chart(items)
    load_genre_chart(items)
    load_style_chart(items)
  end

  def load_format_chart(items)
    @format_chart_data = items.joins(release: :release_formats)
                              .group('release_formats.name')
                              .count
  end

  def load_condition_chart(items)
    @condition_chart_data = items.group(:condition).count
  end

  def load_top_labels(items)
    @top_labels = items.joins(release: { release_labels: :label })
                       .group('labels.name')
                       .order('count_all DESC')
                       .limit(10)
                       .count
  end

  def load_top_artists(items)
    @top_artists = items.joins(release: :artist)
                        .group('artists.name')
                        .order('count_all DESC')
                        .limit(10)
                        .count
  end

  def load_decade_chart(items)
    raw = items.joins(release: :release_group)
               .where.not(release_groups: { year: nil })
               .group(Arel.sql('(release_groups.year / 10) * 10'))
               .order(Arel.sql('(release_groups.year / 10) * 10'))
               .count
    @decade_chart_data = raw.transform_keys { |d| "#{d}s" }
  end

  def load_size_chart(items)
    vinyl = items.joins(release: :release_formats)
                 .where(release_formats: { name: 'Vinyl' })
    seven = vinyl.where("release_formats.descriptions ILIKE '%7\"%'").count
    ten = vinyl.where("release_formats.descriptions ILIKE '%10\"%'").count
    twelve = vinyl.count - seven - ten

    @size_chart_data = {}
    @size_chart_data['12"'] = twelve if twelve.positive?
    @size_chart_data['7"'] = seven if seven.positive?
    @size_chart_data['10"'] = ten if ten.positive?
  end

  def load_color_chart(items)
    raw = items.joins(release: :release_formats)
               .where(release_formats: { name: 'Vinyl' })
               .group(Arel.sql("COALESCE(NULLIF(release_formats.color, ''), 'Black')"))
               .order('count_all DESC')
               .limit(10)
               .count
    @color_chart_data = raw
  end

  def load_genre_chart(items)
    @genre_chart_data = items.joins(release: :release_genres)
                             .group('release_genres.genre')
                             .order('count_all DESC')
                             .limit(10)
                             .count
  end

  def load_style_chart(items)
    @style_chart_data = items.joins(release: :release_styles)
                             .group('release_styles.style')
                             .order('count_all DESC')
                             .limit(10)
                             .count
  end
end
