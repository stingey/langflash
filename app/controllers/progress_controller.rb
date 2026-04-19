class ProgressController < ApplicationController
  def show
    @stats = current_user.user_card_stats.includes(:card)
    @total_attempts = @stats.sum(:total_attempts)
    @correct_attempts = @stats.sum(:correct_attempts)
    @incorrect_attempts = @stats.sum(:incorrect_attempts)
    @accuracy = if @total_attempts.zero?
      0.0
    else
      ((@correct_attempts.to_f / @total_attempts) * 100).round(1)
    end
    @weak_cards = @stats.where("incorrect_attempts > 0").order(:mastery_score, incorrect_attempts: :desc).limit(10)
    @strong_cards = @stats.order(mastery_score: :desc, streak: :desc).limit(10)
  end
end
