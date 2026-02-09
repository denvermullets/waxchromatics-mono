class TradeListItemsController < ApplicationController
  def toggle
    @release = Release.find(params[:release_id])
    collection_item = Current.user.default_collection.collection_items.find_by(release: @release)

    unless collection_item
      set_button_states
      respond_to(&:turbo_stream)
      return
    end

    item = Current.user.trade_list_items.find_by(release: @release)

    if item
      item.destroy!
    else
      Current.user.trade_list_items.create!(release: @release, collection_item: collection_item)
    end

    set_button_states
    respond_to(&:turbo_stream)
  end

  private

  def set_button_states
    @in_collection = Current.user.default_collection.collection_items.exists?(release: @release)
    @in_wantlist = Current.user.wantlist_items.exists?(release: @release)
    @in_trade_list = Current.user.trade_list_items.exists?(release: @release)
  end
end
