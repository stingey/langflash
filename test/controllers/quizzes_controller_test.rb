require "test_helper"

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "start creates a quiz and redirects to show" do
    post start_quiz_url, params: { mode: "en_to_es" }
    assert_redirected_to quiz_url
  end

  test "show works with active session" do
    post start_quiz_url, params: { mode: "en_to_es" }
    get quiz_url
    assert_response :success
  end

  test "results page is reachable" do
    get results_quiz_url
    assert_response :success
  end

  test "start defaults to normal difficulty" do
    post start_quiz_url, params: { mode: "en_to_es" }
    session_id = session[:quiz_session_id]
    assert_equal "normal", QuizSession.find(session_id).difficulty
  end

  test "start persists hard difficulty when requested" do
    post start_quiz_url, params: { mode: "en_to_es", difficulty: "hard" }
    session_id = session[:quiz_session_id]
    assert_equal "hard", QuizSession.find(session_id).difficulty
  end

  test "start ignores unknown difficulty values" do
    post start_quiz_url, params: { mode: "en_to_es", difficulty: "nightmare" }
    session_id = session[:quiz_session_id]
    assert_equal "normal", QuizSession.find(session_id).difficulty
  end

  test "start defaults to all categories" do
    post start_quiz_url, params: { mode: "en_to_es" }
    session_id = session[:quiz_session_id]
    assert_equal "all", QuizSession.find(session_id).category
  end

  test "start persists noun-only category" do
    user = users(:one)
    user.cards.create!(english_text: "fixture-noun", spanish_text: "el-fixture", part_of_speech: "noun")

    post start_quiz_url, params: { mode: "en_to_es", category: "noun" }
    session_id = session[:quiz_session_id]
    assert_equal "noun", QuizSession.find(session_id).category
  end

  test "start ignores unknown category values" do
    post start_quiz_url, params: { mode: "en_to_es", category: "adjective" }
    session_id = session[:quiz_session_id]
    assert_equal "all", QuizSession.find(session_id).category
  end

  test "start refuses category with no matching cards" do
    user = users(:one)
    user.cards.where(part_of_speech: "verb").destroy_all
    user.cards.create!(english_text: "lonely-noun", spanish_text: "el-solo", part_of_speech: "noun")

    post start_quiz_url, params: { mode: "en_to_es", category: "verb" }
    assert_redirected_to cards_url
    assert_match(/verb card/i, flash[:alert])
  end
end
