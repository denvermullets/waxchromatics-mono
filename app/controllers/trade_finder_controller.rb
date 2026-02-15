class TradeFinderController < ApplicationController
  def show
    @matches = TradeFinder::MatchFinder.call(user: Current.user)

    load_sidebar_data
    compute_stats
    apply_filter
    apply_sort
    paginate_matches
  end

  private

  def load_sidebar_data
    @my_trade_items = Current.user.trade_list_items
                             .where(status: 'available')
                             .includes(release: %i[artist release_group])
                             .order('releases.title')
                             .references(:release)
    @my_want_items = Current.user.wantlist_items
                            .includes(release: %i[artist release_group])
                            .order('releases.title')
                            .references(:release)
  end

  def compute_stats
    @offering_count = @my_trade_items.size
    @seeking_count = @my_want_items.size
    @matches_count = @matches.size
    @mutual_count = @matches.count { |m| m[:match_type] == :mutual }
    @they_have_count = @matches.count { |m| m[:match_type] == :they_have }
    @they_want_count = @matches.count { |m| m[:match_type] == :they_want }
  end

  def apply_filter
    @filter = params[:filter].presence || 'all'
    return if @filter == 'all'

    @matches = @matches.select { |m| m[:match_type] == @filter.to_sym }
  end

  def apply_sort
    @sort = params[:sort].presence || 'score'
    @matches = @matches.sort_by { |m| -m[:score] }
  end

  def paginate_matches
    @page = (params[:page] || 1).to_i
    items_per_page = 20
    @total_pages = (@matches.size.to_f / items_per_page).ceil
    @total_pages = 1 if @total_pages < 1
    @page = @page.clamp(1, @total_pages)
    offset = (@page - 1) * items_per_page
    @paginated_matches = @matches[offset, items_per_page] || []
  end
end
