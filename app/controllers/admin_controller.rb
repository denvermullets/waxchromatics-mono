class AdminController < ApplicationController
  before_action :require_admin

  def reclassify_release_groups
    ReclassifyReleaseGroupsJob.perform_later
    redirect_back fallback_location: root_path, notice: 'Reclassify job enqueued.'
  end

  private

  def require_admin
    redirect_to root_path, alert: 'Not authorized.' unless Current.user&.admin?
  end
end
