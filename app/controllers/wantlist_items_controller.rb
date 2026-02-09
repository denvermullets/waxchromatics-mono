class WantlistItemsController < ApplicationController
  def toggle
    @release = Release.find(params[:release_id])
    Current.user.wantlist_items.create!(release: @release)

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
