class ReleasesController < ApplicationController
  def index
    @releases = Release.order(created_at: :desc)
  end

  def new
    @release = Release.new
  end

  def create
    @release = Release.new(release_params)
    assign_master
    if @release.save
      redirect_to @release, notice: 'Release created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @release = Release.find(params[:id])
  end

  private

  def release_params
    params.require(:release).permit(:title, :released, :country, :notes, :status)
  end

  def assign_master
    master_title = params[:release][:master_title].presence
    return unless master_title

    @release.master = Master.find_or_create_by!(title: master_title)
  end
end
