module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc).to_a
      user_ids = @users.map(&:id)

      @cards_counts = Card.where(user_id: user_ids).group(:user_id).count
      @attempts_counts = QuizAttempt.where(user_id: user_ids).group(:user_id).count
      @correct_counts = QuizAttempt.where(user_id: user_ids, correct: true).group(:user_id).count
      @mastered_counts = UserCardStat.mastered.where(user_id: user_ids).group(:user_id).count
    end

    def show
      @user = User.find(params[:id])
      @cards_count = @user.cards.count
      @attempts_count = @user.quiz_attempts.count
      @correct_count = @user.quiz_attempts.where(correct: true).count
      @incorrect_count = @attempts_count - @correct_count
      @accuracy = @user.quiz_accuracy
      @mastered_count = @user.user_card_stats.mastered.count
      @cards = @user.cards.includes(:user_card_stat).order(created_at: :desc)
      @recent_quizzes = @user.quiz_sessions.completed
                             .includes(:quiz_attempts)
                             .order(completed_at: :desc)
                             .limit(10)
    end
  end
end
