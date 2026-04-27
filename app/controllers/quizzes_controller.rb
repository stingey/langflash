class QuizzesController < ApplicationController
  def show
    @quiz_session = current_quiz_session
    return redirect_to dashboard_path, alert: "Start a quiz first." if @quiz_session.blank?

    @question = session[:current_question]&.with_indifferent_access
    if @question.blank?
      return redirect_to results_quiz_path if @quiz_session.completed_at?

      load_next_question!
      @question = session[:current_question]&.with_indifferent_access
    end

    @question_number = @quiz_session.quiz_attempts.count + 1
  end

  def start
    if current_user.cards.empty?
      redirect_to cards_path, alert: "Add at least one card before taking a quiz."
      return
    end

    mode = params[:mode].presence_in(%w[en_to_es es_to_en]) || "en_to_es"
    question_count = params[:question_count].to_i.presence_in(QuizSession::ALLOWED_QUESTION_COUNTS) || 10
    difficulty = params[:difficulty].presence_in(QuizSession::ALLOWED_DIFFICULTIES) || "normal"
    category = params[:category].presence_in(QuizSession::ALLOWED_CATEGORIES) || "all"

    if category != "all" && !current_user.cards.exists?(part_of_speech: category)
      redirect_to cards_path,
                  alert: "Add at least one #{category} card before starting a #{category}-only quiz."
      return
    end

    @quiz_session = current_user.quiz_sessions.create!(
      mode: mode,
      started_at: Time.current,
      question_count: question_count,
      difficulty: difficulty,
      category: category
    )

    session[:quiz_session_id] = @quiz_session.id
    load_next_question!
    redirect_to quiz_path
  end

  def answer
    @quiz_session = current_quiz_session
    return redirect_to dashboard_path, alert: "No active quiz session." if @quiz_session.blank?

    question = session[:current_question]&.with_indifferent_access
    return redirect_to quiz_path, alert: "Question expired. Please try again." if question.blank?

    selected_choice = params[:selected_choice].to_s
    correct = selected_choice == question[:correct_choice]
    attempt_position = @quiz_session.quiz_attempts.count + 1

    @quiz_session.quiz_attempts.create!(
      user: current_user,
      card_id: question[:card_id],
      prompt_text: question[:prompt_text],
      correct_choice: question[:correct_choice],
      selected_choice: selected_choice,
      correct: correct,
      position: attempt_position
    )

    stat = current_user.user_card_stats.find_or_initialize_by(card_id: question[:card_id])
    stat.record_attempt!(correct: correct)

    if correct
      flash[:notice] = "Correct!"
    else
      flash[:alert] = "Not quite. Correct answer: #{question[:correct_choice]}"
    end

    if attempt_position >= @quiz_session.question_count
      @quiz_session.update!(completed_at: Time.current)
      session.delete(:current_question)
      redirect_to results_quiz_path
    else
      load_next_question!
      redirect_to quiz_path
    end
  end

  def results
    @quiz_session = current_quiz_session || current_user.quiz_sessions.completed.order(completed_at: :desc).first
    return redirect_to dashboard_path, alert: "No quiz results found." if @quiz_session.blank?

    @attempts = @quiz_session.quiz_attempts.order(:position)
    @correct_count = @attempts.where(correct: true).count
    @total_count = @attempts.count
    @accuracy = if @total_count.zero?
      0.0
    else
      ((@correct_count.to_f / @total_count) * 100).round(1)
    end
  ensure
    session.delete(:quiz_session_id) if @quiz_session&.completed_at?
    session.delete(:current_question)
  end

  private

  def current_quiz_session
    session_id = session[:quiz_session_id]
    return nil if session_id.blank?

    current_user.quiz_sessions.find_by(id: session_id)
  end

  def load_next_question!
    quiz_session = current_quiz_session
    return if quiz_session.blank?

    selector = QuizQuestionSelector.new(
      user: current_user,
      difficulty: quiz_session.difficulty,
      category: quiz_session.category
    )
    recent_ids = quiz_session.quiz_attempts.order(position: :desc).limit(3).pluck(:card_id)
    card = selector.next_card(recent_ids: recent_ids)
    card ||= current_user.cards.sample
    return if card.blank?

    prompt_text = quiz_session.en_to_es? ? card.english_text : card.spanish_text
    correct_choice = quiz_session.en_to_es? ? card.spanish_text : card.english_text
    choices = selector.choices_for(card: card, mode: quiz_session.mode, count: 4)
    choices << correct_choice unless choices.include?(correct_choice)

    session[:current_question] = {
      "card_id" => card.id,
      "prompt_text" => prompt_text,
      "correct_choice" => correct_choice,
      "choices" => choices.uniq.first(4).shuffle
    }
  end
end
