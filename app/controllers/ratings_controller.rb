class RatingsController < ApplicationController
  before_action :set_trade
  before_action :require_participant
  before_action :require_delivered
  before_action :require_not_rated

  def new
    @rating = Rating.new
    load_form_data
  end

  def create
    @rating = build_rating

    if @rating.save
      redirect_to trade_path(username: params[:username], id: @trade),
                  notice: 'Rating submitted! Thank you for your feedback.'
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_trade
    @trade = Trade.find(params[:trade_id])
  end

  def require_participant
    return if @trade.participant?(Current.user)

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def require_delivered
    return if @trade.delivered?

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'Trade must be delivered to rate.'
  end

  def require_not_rated
    return unless @trade.rating_by(Current.user)

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'You have already rated this trade.'
  end

  def build_rating
    rating = Rating.new(rating_params)
    rating.rateable = @trade
    rating.reviewer = Current.user
    rating.reviewed_user = @trade.partner_for(Current.user)
    rating
  end

  def load_form_data
    @partner = @trade.partner_for(Current.user)
    item_includes = { release: %i[artist release_group release_formats], collection_item: {} }
    @send_items = @trade.items_from(Current.user).includes(**item_includes)
    @receive_items = @trade.items_for(Current.user).includes(**item_includes)
  end

  def rating_params
    params.require(:rating).permit(:overall_rating, :communication_rating, :packing_shipping_rating,
                                   :condition_accuracy, :comments, tags: [])
  end
end
