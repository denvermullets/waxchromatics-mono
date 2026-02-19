class SettingsController < ApplicationController
  before_action :set_user
  before_action :authorize_user

  TOGGLE_CONFIG = {
    'collection_list_view' => { label: 'List view', description: 'Show your collection as a list instead of a grid',
                                enabled: true },
    'accept_trade_requests' => { label: 'Accept trade requests',
                                 description: 'Allow other users to send you trade proposals', enabled: true },
    'require_message_with_trade' => { label: 'Require message with trade',
                                      description: 'Require a message when someone proposes a trade', enabled: true },
    'private_profile' => { label: 'Private profile', description: 'Hide your collection and wantlist from other users',
                           enabled: true },
    'show_location' => { label: 'Show location', description: 'Display your location on your profile', enabled: true }
  }.freeze

  def show; end

  def update_setting
    setting = @user.setting
    if setting.update(setting_params)
      field = setting_params.keys.first
      render partial: 'settings/toggle_row', locals: toggle_locals_for(field), status: :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    @user.destroy
    redirect_to root_path, notice: 'Your account has been deleted.'
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end

  def authorize_user
    redirect_to root_path unless Current.user == @user
  end

  def setting_params
    params.require(:user_setting).permit(
      :accept_trade_requests,
      :collection_list_view,
      :require_message_with_trade,
      :private_profile,
      :show_location
    )
  end

  def toggle_locals_for(field)
    config = TOGGLE_CONFIG[field]
    {
      field: field.to_sym,
      label: config[:label],
      description: config[:description],
      value: @user.setting.send(field),
      enabled: config[:enabled],
      form_url: user_settings_setting_path(username: @user.username)
    }
  end
end
