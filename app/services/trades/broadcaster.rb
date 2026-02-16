module Trades
  class Broadcaster
    attr_reader :trade, :user

    def initialize(trade:, user:)
      @trade = trade
      @user = user
    end

    def broadcast_update
      partner = trade.partner_for(user)
      stream = [trade, :updates, partner]

      broadcast_replace(stream, 'trade_status_badge',
                        'trades/status_badge_broadcast', trade: trade)
      broadcast_replace(stream, 'trade_action_buttons',
                        'trades/action_buttons', trade: trade)
      broadcast_replace(stream, 'trade_activity_log',
                        'trades/activity_log_broadcast', trade: trade)
      broadcast_replace(stream, 'trade_items_section',
                        'trades/items_section_broadcast', trade: trade, partner: user)
    end

    private

    def broadcast_replace(stream, target, partial, **locals)
      Turbo::StreamsChannel.broadcast_replace_later_to(
        stream, target: target, partial: partial, locals: locals
      )
    end
  end
end
