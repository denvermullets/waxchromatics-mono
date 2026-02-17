class TradesController < ApplicationController
  include TradeFormActions

  TRADES_PER_PAGE = 20

  before_action :set_trade, only: %i[show update destroy propose accept decline cancel]
  before_action :require_participant, only: %i[show update]
  before_action :require_modifiable, only: %i[update]
  before_action :require_initiator, only: %i[destroy]

  def index
    base = Trade.involving(Current.user)
    @status_filter = params[:status].presence || 'all'
    @trades = @status_filter == 'all' ? base : base.with_status(@status_filter)
    @trades = @trades.includes(:initiator, :recipient, :trade_items)
                     .order(updated_at: :desc)

    @pagy, @trades = pagy(:offset, @trades, limit: TRADES_PER_PAGE, page_key: 'page')

    compute_index_stats(base)
  end

  def show
    @partner = @trade.partner_for(Current.user)
    @send_items = @trade.items_from(Current.user)
                        .includes(release: %i[artist release_group release_formats], collection_item: {})
    @receive_items = @trade.items_for(Current.user)
                           .includes(release: %i[artist release_group release_formats], collection_item: {})
    @activity = Trades::ActivityLog.new(trade: @trade).entries
    @messages = @trade.trade_messages.includes(:user).order(:created_at)
  end

  def new
    @recipient = User.find(params[:recipient_id]) if params[:recipient_id].present?
    @trade = Trade.new(recipient: @recipient)

    @pre_send_items = load_collection_items(params[:send_ci_ids])
    @pre_receive_items = load_collection_items(params[:receive_ci_ids])
  end

  def create
    @trade = Current.user.initiated_trades.build(trade_params)
    build_new_trade_items
    stamp_proposal if params[:commit] == 'propose'

    if @trade.save
      redirect_to trade_path(username: Current.user.username, id: @trade),
                  notice: @trade.proposed? ? 'Trade proposed!' : 'Trade draft saved.'
    else
      @recipient = @trade.recipient
      @pre_send_items = []
      @pre_receive_items = []
      render :new, status: :unprocessable_entity
    end
  end

  def update
    reconciler = Trades::ItemReconciler.new(trade: @trade, user: Current.user)
    if reconciler.reconcile_and_repropose(send_ids: int_array(:send_items), receive_ids: int_array(:receive_items))
      Trades::Broadcaster.new(trade: @trade, user: Current.user).broadcast_update
      redirect_to trade_path(username: params[:username], id: @trade), notice: 'Trade proposed!'
    else
      redirect_to trade_path(username: params[:username], id: @trade), alert: 'Could not update trade.'
    end
  end

  def destroy
    unless @trade.status == 'draft'
      redirect_to trade_path(username: params[:username], id: @trade), alert: 'Only draft trades can be deleted.'
      return
    end

    @trade.destroy
    redirect_to trades_path(username: params[:username]), notice: 'Trade deleted.'
  end

  def propose
    transition('propose')
  end

  def accept
    transition('accept')
  end

  def decline
    transition('decline')
  end

  def cancel
    transition('cancel')
  end

  private

  def set_trade
    @trade = Trade.find(params[:id])
  end

  def require_participant
    return if @trade.participant?(Current.user)

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def require_modifiable
    return if @trade.can_modify?(Current.user)

    redirect_to trade_path(username: params[:username], id: @trade), alert: 'This trade cannot be modified.'
  end

  def require_initiator
    return if @trade.initiator_id == Current.user.id

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def trade_params
    params.require(:trade).permit(:recipient_id)
  end

  def build_new_trade_items
    Trades::ItemReconciler.new(trade: @trade, user: Current.user)
                          .build_from_params(send_ids: params[:send_items], receive_ids: params[:receive_items])
  end

  def stamp_proposal
    @trade.status = 'proposed'
    @trade.proposed_at = Time.current
    @trade.proposed_by = Current.user
  end

  def int_array(key)
    Array(params[key]).map(&:to_i)
  end

  def transition(action)
    machine = Trades::StatusMachine.new(trade: @trade, user: Current.user, action: action)
    trade_url = trade_path(username: params[:username], id: @trade)
    if machine.call
      Trades::Broadcaster.new(trade: @trade, user: Current.user).broadcast_update
      redirect_to trade_url, notice: "Trade #{@trade.status}."
    else
      redirect_to trade_url, alert: machine.error
    end
  end

  def compute_index_stats(base)
    @stats = {
      active: base.active.count,
      completed: base.where(status: %w[accepted delivered]).count,
      pending: base.with_status('proposed').count
    }

    @status_counts = Trade::STATUSES.each_with_object({}) do |s, h|
      h[s] = base.with_status(s).count
    end
    @status_counts['all'] = base.count
  end
end
