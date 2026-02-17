class TradeItemsController < ApplicationController
  include TradeSearch

  before_action :set_trade
  before_action :require_modifiable

  def search_send
    @items = exclude_existing(search_collection_items(Current.user, params[:q]))
    @side = 'send'
    render 'trade_items/search_results', layout: false
  end

  def search_receive
    partner = @trade.partner_for(Current.user)
    @items = exclude_existing(search_collection_items(partner, params[:q]))
    @side = 'receive'
    render 'trade_items/search_results', layout: false
  end

  private

  def set_trade
    @trade = Trade.find(params[:trade_id])
  end

  def require_modifiable
    return if @trade.can_modify?(Current.user)

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'This trade cannot be modified.'
  end

  def exclude_existing(items)
    existing_ids = @trade.trade_items.pluck(:collection_item_id)
    return items if existing_ids.empty?

    items.where.not(id: existing_ids)
  end
end
