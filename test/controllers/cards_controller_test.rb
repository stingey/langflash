require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should get index" do
    get cards_url
    assert_response :success
  end

  test "should get show" do
    get card_url(cards(:one))
    assert_response :success
  end

  test "translate suggestion returns success" do
    get translate_suggestion_cards_url, params: { english_text: "dog" }
    assert_response :success
  end
end
