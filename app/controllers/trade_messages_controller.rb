class TradeMessagesController < ApplicationController
  before_action :set_trade
  before_action :require_participant

  def create
    @message = @trade.trade_messages.build(message_params)
    @message.user = Current.user

    if @message.save
      partner = @trade.partner_for(Current.user)
      @message.broadcast_append_later_to [@trade, :messages, partner],
                                         target: 'trade_messages',
                                         partial: 'trade_messages/message',
                                         locals: { trade_message: @message, own: false }

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to trade_path(username: params[:username], id: @trade) }
      end
    else
      redirect_to trade_path(username: params[:username], id: @trade), alert: 'Message could not be sent.'
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

  def message_params
    params.require(:trade_message).permit(:body)
  end
end
