class ConnectionsController < ApplicationController
  def show; end

  def search
    result = Connections::PathFinder.call(
      artist_a_id: params[:artist_a_id],
      artist_b_id: params[:artist_b_id]
    )

    if result[:error]
      render partial: 'connections/error', locals: { message: result[:error] }, layout: false
    elsif result[:found]
      render partial: 'connections/results', locals: {
        degrees: result[:degrees],
        path: result[:shortest_path],
        alternate_paths: result[:alternate_paths],
        artist_a: result[:artist_a],
        artist_b: result[:artist_b]
      }, layout: false
    else
      render partial: 'connections/no_result', locals: {
        artist_a: result[:artist_a],
        artist_b: result[:artist_b]
      }, layout: false
    end
  end
end
