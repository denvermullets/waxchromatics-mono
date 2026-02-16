class TradesController < ApplicationController
  include TradeSearch

  TRADES_PER_PAGE = 20

  before_action :set_trade, only: %i[show destroy propose accept decline cancel]
  before_action :require_participant, only: %i[show]
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
                        .includes(release: %i[artist release_group], collection_item: {})
    @receive_items = @trade.items_for(Current.user)
                           .includes(release: %i[artist release_group], collection_item: {})
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

    build_trade_items

    if params[:commit] == 'propose'
      @trade.status = 'proposed'
      @trade.proposed_at = Time.current
    end

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

  # --- Turbo Frame search endpoints ---

  def search_users
    @users = if params[:q].present? && params[:q].length >= 2
               User.where.not(id: Current.user.id)
                   .where('username ILIKE ?', "%#{params[:q]}%")
                   .limit(10)
             else
               User.none
             end

    render layout: false
  end

  def search_collection
    @items = search_collection_items(Current.user, params[:q])
    @side = 'send'

    render 'trades/search_collection_results', layout: false
  end

  def search_recipient_collection
    return head(:bad_request) unless params[:recipient_id].present?

    recipient = User.find(params[:recipient_id])
    @items = search_collection_items(recipient, params[:q])
    @side = 'receive'

    render 'trades/search_collection_results', layout: false
  end

  # --- Turbo Stream actions ---

  def select_recipient
    @recipient = User.find(params[:recipient_id])
    respond_to(&:turbo_stream)
  end

  def add_item
    @collection_item = CollectionItem.joins(release: %i[artist release_group]).find(params[:collection_item_id])
    @side = params[:side]
    respond_to(&:turbo_stream)
  end

  private

  def set_trade
    @trade = Trade.find(params[:id])
  end

  def require_participant
    return if @trade.participant?(Current.user)

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def require_initiator
    return if @trade.initiator_id == Current.user.id

    redirect_to trades_path(username: params[:username]), alert: 'Not authorized.'
  end

  def trade_params
    params.require(:trade).permit(:recipient_id, :notes)
  end

  def build_trade_items
    (params[:send_items] || []).each do |ci_id|
      col_item = CollectionItem.find(ci_id)
      @trade.trade_items.build(user: Current.user, release: col_item.release, collection_item: col_item)
    end

    (params[:receive_items] || []).each do |ci_id|
      col_item = CollectionItem.find(ci_id)
      @trade.trade_items.build(user: @trade.recipient, release: col_item.release, collection_item: col_item)
    end
  end

  def transition(action)
    machine = Trades::StatusMachine.new(trade: @trade, user: Current.user, action: action)
    trade_url = trade_path(username: params[:username], id: @trade)
    if machine.call
      redirect_to trade_url, notice: "Trade #{@trade.status}."
    else
      redirect_to trade_url, alert: machine.error
    end
  end

  def compute_index_stats(base)
    @stats = {
      active: base.active.count,
      completed: base.with_status('accepted').count,
      pending: base.with_status('proposed').count
    }

    @status_counts = Trade::STATUSES.each_with_object({}) do |s, h|
      h[s] = base.with_status(s).count
    end
    @status_counts['all'] = base.count
  end
end
