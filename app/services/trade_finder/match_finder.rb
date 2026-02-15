module TradeFinder
  class MatchFinder < Service
    def initialize(user:)
      @user = user
    end

    def call
      my_wantlist_release_ids = @user.wantlist_items.pluck(:release_id)
      my_trade_release_ids = @user.trade_list_items.where(status: 'available').pluck(:release_id)

      return [] if my_wantlist_release_ids.empty? && my_trade_release_ids.empty?

      they_have = find_they_have(my_wantlist_release_ids)
      they_want = find_they_want(my_trade_release_ids)

      merge_matches(they_have, they_want)
    end

    private

    # Other users' available trade items where release_id is in MY wantlist
    def find_they_have(my_wantlist_release_ids)
      return {} if my_wantlist_release_ids.empty?

      TradeListItem
        .where(status: 'available', release_id: my_wantlist_release_ids)
        .where.not(user_id: @user.id)
        .includes(release: %i[artist release_group], user: [])
        .group_by(&:user_id)
    end

    # Other users' wantlist items where release_id is in MY trade list
    def find_they_want(my_trade_release_ids)
      return {} if my_trade_release_ids.empty?

      WantlistItem
        .where(release_id: my_trade_release_ids)
        .where.not(user_id: @user.id)
        .includes(release: %i[artist release_group], user: [])
        .group_by(&:user_id)
    end

    def merge_matches(they_have, they_want)
      user_ids = (they_have.keys + they_want.keys).uniq
      users_by_id = User.where(id: user_ids).index_by(&:id)

      user_ids.map { |uid| build_match(uid, they_have, they_want, users_by_id) }
              .sort_by { |m| -m[:score] }
    end

    def build_match(uid, they_have, they_want, users_by_id)
      have_items = they_have[uid] || []
      want_items = they_want[uid] || []

      {
        user: users_by_id[uid],
        match_type: determine_match_type(have_items, want_items),
        they_have_items: have_items,
        they_want_items: want_items,
        they_have_count: have_items.size,
        they_want_count: want_items.size,
        score: have_items.size + want_items.size
      }
    end

    def determine_match_type(have_items, want_items)
      if have_items.any? && want_items.any?
        :mutual
      elsif have_items.any?
        :they_have
      else
        :they_want
      end
    end
  end
end
