require "test_helper"

class QuizQuestionSelectorTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.cards.destroy_all
  end

  test "hard mode restricts the pool to the top half of tiers" do
    create_card("noun-tier-1", tier: 1)
    create_card("noun-tier-2", tier: 2)
    create_card("noun-tier-3", tier: 3)
    create_card("noun-tier-4", tier: 4)

    selector = QuizQuestionSelector.new(user: @user, difficulty: :hard)

    selected_ranks = 50.times.map { selector.next_card.frequency_rank }.uniq.sort
    # max_tier=4, threshold=ceil(4/2)=2, so only tiers >= 2 are eligible
    assert_equal [2, 3, 4], selected_ranks
  end

  test "hard mode excludes cards without a frequency_rank" do
    create_card("ranked-1", tier: 5)
    create_card("ranked-2", tier: 6)
    create_card("custom", tier: nil)

    selector = QuizQuestionSelector.new(user: @user, difficulty: :hard)

    50.times do
      card = selector.next_card
      assert card.frequency_rank.present?, "hard mode should never pick unranked cards"
    end
  end

  test "hard mode returns nil when no ranked cards exist" do
    create_card("custom-1", tier: nil)
    create_card("custom-2", tier: nil)

    selector = QuizQuestionSelector.new(user: @user, difficulty: :hard)
    assert_nil selector.next_card
  end

  test "hard mode skews selection toward rarer tiers" do
    create_card("tier-5", tier: 5)
    create_card("tier-10", tier: 10)

    selector = QuizQuestionSelector.new(user: @user, difficulty: :hard)
    counts = Hash.new(0)
    1000.times { counts[selector.next_card.frequency_rank] += 1 }

    assert counts[10] > counts[5],
      "expected tier 10 to be picked more than tier 5 in hard mode (got #{counts.inspect})"
  end

  test "normal mode ignores frequency_rank when filtering" do
    create_card("tier-1", tier: 1)
    create_card("custom", tier: nil)

    selector = QuizQuestionSelector.new(user: @user, difficulty: :normal)
    seen = Set.new
    50.times { seen << selector.next_card.english_text }

    assert seen.include?("tier-1")
    assert seen.include?("custom")
  end

  test "noun category restricts the pool to nouns" do
    create_card("a-noun", tier: 1, part_of_speech: "noun")
    create_card("b-noun", tier: 2, part_of_speech: "noun")
    create_card("a-verb", tier: 1, part_of_speech: "verb")

    selector = QuizQuestionSelector.new(user: @user, category: "noun")
    parts = 50.times.map { selector.next_card.part_of_speech }.uniq
    assert_equal ["noun"], parts
  end

  test "verb category restricts the pool to verbs" do
    create_card("a-noun", tier: 1, part_of_speech: "noun")
    create_card("a-verb", tier: 1, part_of_speech: "verb")
    create_card("b-verb", tier: 2, part_of_speech: "verb")

    selector = QuizQuestionSelector.new(user: @user, category: "verb")
    parts = 50.times.map { selector.next_card.part_of_speech }.uniq
    assert_equal ["verb"], parts
  end

  test "all category does not filter by part_of_speech" do
    create_card("a-noun", tier: 1, part_of_speech: "noun")
    create_card("a-verb", tier: 1, part_of_speech: "verb")

    selector = QuizQuestionSelector.new(user: @user, category: "all")
    parts = 50.times.map { selector.next_card.part_of_speech }.uniq.sort
    assert_equal ["noun", "verb"], parts
  end

  test "unknown category falls back to all" do
    create_card("a-noun", tier: 1, part_of_speech: "noun")
    create_card("a-verb", tier: 1, part_of_speech: "verb")

    selector = QuizQuestionSelector.new(user: @user, category: "bogus")
    parts = 50.times.map { selector.next_card.part_of_speech }.uniq.sort
    assert_equal ["noun", "verb"], parts
  end

  test "category combines with hard mode" do
    create_card("noun-tier-1", tier: 1, part_of_speech: "noun")
    create_card("noun-tier-3", tier: 3, part_of_speech: "noun")
    create_card("noun-tier-4", tier: 4, part_of_speech: "noun")
    create_card("verb-tier-4", tier: 4, part_of_speech: "verb")

    selector = QuizQuestionSelector.new(user: @user, difficulty: :hard, category: "noun")

    50.times do
      card = selector.next_card
      assert_equal "noun", card.part_of_speech
      # max_tier among nouns = 4, threshold = ceil(4/2) = 2
      assert card.frequency_rank >= 2
    end
  end

  private

  def create_card(english, tier:, part_of_speech: "noun")
    @user.cards.create!(
      english_text: english,
      spanish_text: "es-#{english}",
      part_of_speech: part_of_speech,
      frequency_rank: tier
    )
  end
end
