class TradesController < ApplicationController
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
  end

  def new
    @recipient = User.find(params[:recipient_id]) if params[:recipient_id].present?
    @trade = Trade.new(recipient: @recipient)

    # Both sides pass collection_item_ids directly
    @pre_send_items = params[:send_ci_ids].present? ? collection_items_by_ids(Array(params[:send_ci_ids])) : []
    @pre_receive_items = params[:receive_ci_ids].present? ? collection_items_by_ids(Array(params[:receive_ci_ids])) : []
  end

  def create
    @trade = Current.user.initiated_trades.build(trade_params)

    build_trade_items

    if params[:commit] == 'propose'
      @trade.status = 'proposed'
      @trade.proposed_at = Time.current
    end

    if @trade.save
      redirect_to @trade, notice: @trade.proposed? ? 'Trade proposed!' : 'Trade draft saved.'
    else
      @recipient = @trade.recipient
      @pre_send_items = []
      @pre_receive_items = []
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    unless @trade.status == 'draft'
      redirect_to @trade, alert: 'Only draft trades can be deleted.'
      return
    end

    @trade.destroy
    redirect_to trades_path, notice: 'Trade deleted.'
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

  # JSON search endpoints for the trade form
  def search_users
    users = User.where.not(id: Current.user.id)
                .where('username ILIKE ?', "%#{params[:q]}%")
                .limit(10)
                .select(:id, :username, :avatar_url)
    render json: users
  end

  def search_collection
    items = collection_items_for(Current.user, params[:q])
    render json: items
  end

  def search_recipient_collection
    recipient = User.find(params[:recipient_id])
    items = collection_items_for(recipient, params[:q])
    render json: items
  end

  private

  def set_trade
    @trade = Trade.find(params[:id])
  end

  def require_participant
    redirect_to trades_path, alert: 'Not authorized.' unless @trade.participant?(Current.user)
  end

  def require_initiator
    redirect_to trades_path, alert: 'Not authorized.' unless @trade.initiator_id == Current.user.id
  end

  def trade_params
    params.require(:trade).permit(:recipient_id, :notes)
  end

  def build_trade_items
    (params[:send_items] || []).each do |ci_id|
      ci = CollectionItem.find(ci_id)
      @trade.trade_items.build(user: Current.user, release: ci.release, collection_item: ci)
    end

    (params[:receive_items] || []).each do |ci_id|
      ci = CollectionItem.find(ci_id)
      @trade.trade_items.build(user: @trade.recipient, release: ci.release, collection_item: ci)
    end
  end

  def transition(action)
    machine = Trades::StatusMachine.new(trade: @trade, user: Current.user, action: action)
    if machine.call
      redirect_to @trade, notice: "Trade #{@trade.status}."
    else
      redirect_to @trade, alert: machine.error
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

  def collection_items_for(user, query)
    scope = CollectionItem.joins(:collection, release: %i[artist release_group])
                          .where(collections: { user_id: user.id })

    if query.present?
      scope = scope.where(
        'releases.title ILIKE :q OR artists.name ILIKE :q',
        q: "%#{query}%"
      )
    end

    scope.limit(20).map { |ci| serialize_collection_item(ci) }
  end

  def collection_items_by_ids(ci_ids)
    CollectionItem.joins(release: %i[artist release_group])
                  .where(id: ci_ids)
                  .map { |ci| serialize_collection_item(ci) }
  end

  def serialize_collection_item(col_item)
    {
      id: col_item.id,
      release_id: col_item.release_id,
      title: col_item.release.title,
      artist: col_item.release.artist&.name,
      cover_art_url: col_item.release.release_group&.cover_art_url,
      condition: col_item.condition
    }
  end
end
