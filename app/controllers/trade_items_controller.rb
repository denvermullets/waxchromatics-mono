class TradeItemsController < ApplicationController
  include TradeSearch

  before_action :set_trade
  before_action :require_modifiable

  def create
    col_item = CollectionItem.find(params[:collection_item_id])
    @trade_item = @trade.trade_items.build(
      user: col_item.collection.user,
      release: col_item.release,
      collection_item: col_item
    )

    if @trade_item.save
      reset_proposal!
      load_turbo_context
      respond_to(&:turbo_stream)
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @trade_item = @trade.trade_items.find(params[:id])
    @trade_item.destroy!
    reset_proposal!
    load_turbo_context
    respond_to(&:turbo_stream)
  end

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

  def reset_proposal!
    return unless @trade.proposed?

    @trade.update!(proposed_by: Current.user, proposed_at: Time.current)
  end

  def load_turbo_context
    @partner = @trade.partner_for(Current.user)
    @send_items = @trade.items_from(Current.user)
                        .includes(release: %i[artist release_group release_formats], collection_item: {})
    @receive_items = @trade.items_for(Current.user)
                           .includes(release: %i[artist release_group release_formats], collection_item: {})
  end
end
