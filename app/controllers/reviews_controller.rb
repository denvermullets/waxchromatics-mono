class ReviewsController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by!(username: params[:username])
    @own_profile = Current.user == @user

    visible = @user.ratings_received.visible
    @total_ratings = visible.count
    @completed_trade_count = @user.completed_trade_count

    if @total_ratings.positive?
      load_averages(visible)
      load_condition_breakdown(visible)
      load_tag_frequencies(visible)
    end

    load_ratings(visible)
  end

  private

  def load_averages(visible)
    @avg_overall = visible.average(:overall_rating)&.round(1)
    @avg_communication = visible.average(:communication_rating)&.round(1)
    @avg_packing = visible.average(:packing_shipping_rating)&.round(1)
  end

  def load_condition_breakdown(visible)
    counts = visible.group(:condition_accuracy).count
    total = counts.values.sum.to_f

    accurate_or_better = (counts.fetch('accurate', 0) + counts.fetch('better_than_listed', 0))
    slightly_off = counts.fetch('slightly_off', 0)
    worse = counts.fetch('worse_than_listed', 0)

    @condition_breakdown = if total.positive?
                             {
                               accurate_or_better: (accurate_or_better / total * 100).round(0),
                               slightly_off: (slightly_off / total * 100).round(0),
                               worse: (worse / total * 100).round(0)
                             }
                           else
                             { accurate_or_better: 0, slightly_off: 0, worse: 0 }
                           end
  end

  def load_tag_frequencies(visible)
    tag_counts = Hash.new(0)
    visible.where.not(tags: nil).pluck(:tags).each do |tags|
      tags.each { |t| tag_counts[t] += 1 }
    end

    total = @total_ratings.to_f
    @tag_frequencies = tag_counts.transform_values { |c| (c / total * 100).round(0) }
                                 .sort_by { |_, pct| -pct }
                                 .to_h
  end

  def load_ratings(visible)
    scope = visible.includes(:reviewer, rateable: { trade_items: { release: %i[artist release_group] } })
                   .order(created_at: :desc)

    if params[:stars].present?
      stars = params[:stars].to_i
      scope = if stars <= 3
                scope.where(overall_rating: 1..3)
              else
                scope.where(overall_rating: stars)
              end
    end

    @pagy, @ratings = pagy(:offset, scope, limit: 10, page_key: :page)
  end
end
