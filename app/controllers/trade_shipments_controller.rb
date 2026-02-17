class TradeShipmentsController < ApplicationController
  before_action :set_trade
  before_action :require_participant
  before_action :require_accepted
  before_action :set_shipment, only: :update
  before_action :require_owner, only: :update

  def create
    @shipment = @trade.trade_shipments.build(shipment_params.merge(user: Current.user))

    if @shipment.save
      after_save
      respond_to(&:turbo_stream)
    else
      redirect_to trade_path(username: params[:username], id: @trade),
                  alert: @shipment.errors.full_messages.to_sentence
    end
  end

  def update
    if @shipment.update(shipment_params)
      after_save
      respond_to(&:turbo_stream)
    else
      redirect_to trade_path(username: params[:username], id: @trade),
                  alert: @shipment.errors.full_messages.to_sentence
    end
  end

  private

  def set_trade
    @trade = Trade.find(params[:trade_id])
  end

  def set_shipment
    @shipment = @trade.trade_shipments.find(params[:id])
  end

  def require_participant
    return if @trade.participant?(Current.user)

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def require_accepted
    return if @trade.accepted?

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'Trade must be accepted first.'
  end

  def require_owner
    return if @shipment.user_id == Current.user.id

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'Not authorized.'
  end

  def shipment_params
    params.require(:trade_shipment).permit(:carrier, :tracking_number, :status, :last_event_description, :last_event_at)
  end

  def after_save
    @partner = @trade.partner_for(Current.user)
    @activity = Trades::ActivityLog.new(trade: @trade).entries
    broadcast_to_partner
  end

  def broadcast_to_partner
    Turbo::StreamsChannel.broadcast_replace_later_to(
      [@trade, :shipments, @partner],
      target: 'their_shipment',
      partial: 'trade_shipments/their_shipment_broadcast',
      locals: { shipment: @shipment, trade: @trade }
    )

    Turbo::StreamsChannel.broadcast_replace_later_to(
      [@trade, :shipments, @partner],
      target: 'trade_activity_log',
      partial: 'trades/activity_log_broadcast',
      locals: { trade: @trade }
    )
  end
end
