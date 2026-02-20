class JobMetricsController < ApplicationController
  before_action :require_admin

  def show
    @range = %w[1h 24h 7d 30d].include?(params[:range]) ? params[:range] : '24h'
    load_stats
    load_chart_series
  end

  private

  def load_stats
    @finished_count = SolidQueue::Job.where(finished_at: range_start..Time.current).count
    @in_progress_count = SolidQueue::ClaimedExecution.count
    @queued_count = SolidQueue::ReadyExecution.count
    @failed_count = SolidQueue::FailedExecution.count
  end

  def load_chart_series
    enqueued_raw = build_series(:created_at)
    finished_raw = build_series(:finished_at)
    all_times = (enqueued_raw.keys | finished_raw.keys).sort
    @labels = all_times.map { |t| format_label(t) }
    @enqueued_series = all_times.map { |t| enqueued_raw[t] || 0 }
    @finished_series = all_times.map { |t| finished_raw[t] || 0 }
  end

  def require_admin
    return if Current.user&.admin?

    redirect_to root_path, alert: 'Not authorized'
  end

  def range_start
    case @range
    when '1h'  then 1.hour.ago
    when '7d'  then 7.days.ago
    when '30d' then 30.days.ago
    else            24.hours.ago
    end
  end

  def trunc_unit
    case @range
    when '1h'  then 'minute'
    when '24h' then 'hour'
    else            'day'
    end
  end

  def build_series(column)
    SolidQueue::Job
      .where(column => range_start..Time.current)
      .group(Arel.sql("date_trunc('#{trunc_unit}', #{column})"))
      .order(Arel.sql("date_trunc('#{trunc_unit}', #{column})"))
      .count
  end

  def format_label(time)
    t = time.in_time_zone
    case @range
    when '1h'
      t.strftime('%-l:%M %p')
    when '24h'
      t.strftime('%-l %p')
    else
      t.strftime('%-m/%-d')
    end
  end
end
