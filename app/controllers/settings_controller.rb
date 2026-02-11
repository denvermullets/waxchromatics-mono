class SettingsController < ApplicationController
  before_action :set_user
  before_action :authorize_user

  def show; end

  def update
    if @user.update(user_params)
      redirect_to user_settings_path(username: @user.username), notice: 'Settings updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end

  def authorize_user
    redirect_to root_path unless Current.user == @user
  end

  def user_params
    params.require(:user).permit(:bio, :location, :avatar_url, :default_collection_view)
  end
end
