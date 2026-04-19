require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    sign_in users(:one)
    get progress_url
    assert_response :success
  end
end
