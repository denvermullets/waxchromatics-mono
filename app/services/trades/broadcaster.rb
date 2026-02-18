module Trades
  class Broadcaster
    attr_reader :trade, :user

    def initialize(trade:, user:)
      @trade = trade
      @user = user
    end

    def broadcast_update
      partner = trade.partner_for(user)
      broadcast_to_user(partner)
    end

    def broadcast_to_all
      broadcast_to_user(trade.initiator)
      broadcast_to_user(trade.recipient)
    end

    private

    def broadcast_to_user(target_user)
      stream = [trade, :updates, target_user]

      broadcast_replace(stream, 'trade_status_badge',
                        'trades/status_badge_broadcast', trade: trade)
      broadcast_replace(stream, 'trade_action_buttons',
                        'trades/action_buttons_broadcast', trade: trade, user: target_user)
      broadcast_replace(stream, 'trade_activity_log',
                        'trades/activity_log_broadcast', trade: trade)
      broadcast_replace(stream, 'trade_items_section',
                        'trades/items_section_broadcast', trade: trade, partner: target_user)
    end

    def broadcast_replace(stream, target, partial, **locals)
      Turbo::StreamsChannel.broadcast_replace_later_to(
        stream, target: target, partial: partial, locals: locals
      )
    end
  end
end
