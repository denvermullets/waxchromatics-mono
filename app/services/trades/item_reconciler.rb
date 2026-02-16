module Trades
  class ItemReconciler
    attr_reader :trade, :user

    def initialize(trade:, user:)
      @trade = trade
      @user = user
    end

    def reconcile_and_repropose(send_ids:, receive_ids:)
      reconcile(send_ids: send_ids, receive_ids: receive_ids)
      mark_proposed
      trade.save
    end

    def build_from_params(send_ids:, receive_ids:)
      build_items(Array(send_ids), user)
      build_items(Array(receive_ids), trade.recipient)
    end

    private

    def reconcile(send_ids:, receive_ids:)
      submitted_all = send_ids + receive_ids
      trade.trade_items.where.not(collection_item_id: submitted_all).destroy_all

      existing_ids = trade.trade_items.pluck(:collection_item_id)
      partner = trade.partner_for(user)
      build_items(send_ids - existing_ids, user)
      build_items(receive_ids - existing_ids, partner)
    end

    def mark_proposed
      trade.proposed_by = user
      trade.proposed_at = Time.current
      trade.status = 'proposed'
    end

    def build_items(ci_ids, owner)
      ci_ids.each do |ci_id|
        col_item = CollectionItem.find(ci_id)
        trade.trade_items.build(user: owner, release: col_item.release, collection_item: col_item)
      end
    end
  end
end
