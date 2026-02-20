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
    @queue_names = SolidQueue::Job.where(created_at: range_start..Time.current).distinct.pluck(:queue_name).sort
    per_queue = build_per_queue_series
    @labels = per_queue[:times].map(&:iso8601)
    @queue_datasets = per_queue[:datasets]
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

  def build_per_queue_series
    enqueued_rows = grouped_counts(:created_at)
    finished_rows = grouped_counts(:finished_at)
    all_times = (enqueued_rows.keys.map(&:last) | finished_rows.keys.map(&:last)).uniq.sort
    datasets = @queue_names.flat_map { |q| queue_datasets(q, all_times, enqueued_rows, finished_rows) }

    { times: all_times, datasets: datasets }
  end

  def queue_datasets(queue, all_times, enqueued_rows, finished_rows)
    [
      { label: "#{queue} (enqueued)", data: all_times.map { |t| enqueued_rows[[queue, t]] || 0 },
        queue: queue, kind: 'enqueued' },
      { label: "#{queue} (finished)", data: all_times.map { |t| finished_rows[[queue, t]] || 0 },
        queue: queue, kind: 'finished' }
    ]
  end

  def grouped_counts(column)
    SolidQueue::Job
      .where(column => range_start..Time.current)
      .group(:queue_name, Arel.sql("date_trunc('#{trunc_unit}', #{column})"))
      .order(Arel.sql("date_trunc('#{trunc_unit}', #{column})"))
      .count
  end
end
