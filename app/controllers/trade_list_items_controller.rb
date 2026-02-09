class TradeListItemsController < ApplicationController
  def toggle
    @release = Release.find(params[:release_id])
    collection_item = Current.user.default_collection.collection_items.find_by(release: @release)

    unless collection_item
      set_button_states
      respond_to(&:turbo_stream)
      return
    end

    Current.user.trade_list_items.create!(release: @release, collection_item: collection_item)

    set_button_states
    respond_to(&:turbo_stream)
  end

  private

  def set_button_states
    @collection_count = Current.user.default_collection.collection_items.where(release: @release).count
    @wantlist_count = Current.user.wantlist_items.where(release: @release).count
    @trade_list_count = Current.user.trade_list_items.where(release: @release).count
  end
end
