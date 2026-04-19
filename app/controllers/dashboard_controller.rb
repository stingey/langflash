class DashboardController < ApplicationController
  def show
    @cards_count = current_user.cards.count
    @attempts_count = current_user.quiz_attempts.count
    @correct_count = current_user.quiz_attempts.where(correct: true).count
    @incorrect_count = @attempts_count - @correct_count
    @accuracy = current_user.quiz_accuracy
    @mastered_count = current_user.user_card_stats.mastered.count
    @recent_cards = current_user.cards.order(created_at: :desc).limit(6)
    @recent_quizzes = current_user.quiz_sessions.completed
                                  .includes(:quiz_attempts)
                                  .order(completed_at: :desc)
                                  .limit(5)
  end
end
