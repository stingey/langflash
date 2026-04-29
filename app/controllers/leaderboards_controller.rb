class LeaderboardsController < ApplicationController
  PERIODS = {
    "week"  => { label: "Past week",  duration: 1.week,  min_attempts: 20 },
    "month" => { label: "Past month", duration: 1.month, min_attempts: 50 },
    "all"   => { label: "All time",   duration: nil,     min_attempts: 200 }
  }.freeze

  DEFAULT_PERIOD = "week"

  def index
    @period = PERIODS.key?(params[:period]) ? params[:period] : DEFAULT_PERIOD
    period_config = PERIODS[@period]
    @period_label = period_config[:label]
    @min_attempts = period_config[:min_attempts]
    @periods = PERIODS

    scope = QuizAttempt.all
    if period_config[:duration]
      @since = period_config[:duration].ago
      scope = scope.where("quiz_attempts.created_at >= ?", @since)
    end

    rows = scope
      .group(:user_id)
      .pluck(
        :user_id,
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(CASE WHEN correct THEN 1 ELSE 0 END)"),
        Arel.sql("MAX(created_at)")
      )

    qualifying = rows.filter_map do |user_id, total, correct, last_at|
      total = total.to_i
      next if total < @min_attempts

      correct = correct.to_i
      {
        user_id: user_id,
        total: total,
        correct: correct,
        accuracy: (correct.to_f / total * 100).round(1),
        last_attempt_at: last_at
      }
    end

    users_by_id = User.where(id: qualifying.map { |r| r[:user_id] }).index_by(&:id)

    @entries = qualifying
      .sort_by { |r| [-r[:accuracy], -r[:total], users_by_id[r[:user_id]]&.created_at || Time.current] }
      .map { |r| r.merge(user: users_by_id[r[:user_id]]) }
      .reject { |r| r[:user].nil? }
  end
end
