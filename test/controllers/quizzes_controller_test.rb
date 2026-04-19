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
end
