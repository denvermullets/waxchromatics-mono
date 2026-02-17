module TradeFormActions
  extend ActiveSupport::Concern

  included do
    include TradeSearch
  end

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

  def select_recipient
    @recipient = User.find(params[:recipient_id])
    respond_to(&:turbo_stream)
  end

  def add_item
    @collection_item = CollectionItem.joins(release: %i[artist release_group]).find(params[:collection_item_id])
    @side = params[:side]
    respond_to(&:turbo_stream)
  end

  def remove_item
    @side = params[:side]
    @item_id = params[:item_id]
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("#{@side}_item_#{@item_id}"),
          turbo_stream.remove("#{@side}_hidden_#{@item_id}")
        ]
      end
    end
  end
end
