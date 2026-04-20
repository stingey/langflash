module Admin
  class UsersController < BaseController
    def index
      @users = User.left_joins(:cards, :quiz_attempts, :user_card_stats)
                   .select(<<~SQL.squish)
                     users.*,
                     COUNT(DISTINCT cards.id) AS cards_count,
                     COUNT(DISTINCT quiz_attempts.id) AS attempts_count,
                     COUNT(DISTINCT quiz_attempts.id) FILTER (WHERE quiz_attempts.correct) AS correct_count,
                     COUNT(DISTINCT user_card_stats.id) FILTER (
                       WHERE user_card_stats.mastery_score > #{UserCardStat::MASTERY_THRESHOLD}
                       AND user_card_stats.total_attempts >= #{UserCardStat::MASTERY_MIN_ATTEMPTS}
                     ) AS mastered_count
                   SQL
                   .group("users.id")
                   .order("users.created_at DESC")
    end

    def show
      @user = User.find(params[:id])
      @cards_count = @user.cards.count
      @attempts_count = @user.quiz_attempts.count
      @correct_count = @user.quiz_attempts.where(correct: true).count
      @incorrect_count = @attempts_count - @correct_count
      @accuracy = @user.quiz_accuracy
      @mastered_count = @user.user_card_stats.mastered.count
      @recent_cards = @user.cards.order(created_at: :desc).limit(6)
      @recent_quizzes = @user.quiz_sessions.completed
                             .includes(:quiz_attempts)
                             .order(completed_at: :desc)
                             .limit(10)
    end
  end
end
