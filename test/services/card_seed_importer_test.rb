require "test_helper"

class CardSeedImporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.cards.destroy_all
  end

  test "imported cards receive a frequency_rank tier" do
    CardSeedImporter.import(@user, "common_nouns.csv", batch_size: 5)

    cards = @user.cards.order(:created_at)
    assert cards.any?, "expected the importer to create at least one card"
    cards.each do |card|
      assert card.frequency_rank.present?, "expected #{card.english_text} to have a frequency_rank"
      assert card.frequency_rank >= 1
    end
  end

  test "first 100 rows of the CSV land in tier 1" do
    CardSeedImporter.import(@user, "common_nouns.csv", batch_size: 100)

    ranks = @user.cards.order(:created_at).limit(100).pluck(:frequency_rank)
    assert_equal 100, ranks.size
    assert ranks.all? { |r| r == 1 }, "expected the first 100 imports to all be tier 1, got #{ranks.uniq}"
  end

  test "row 101 of the CSV lands in tier 2" do
    CardSeedImporter.import(@user, "common_nouns.csv", batch_size: 101)

    ranks = @user.cards.order(:created_at).pluck(:frequency_rank)
    assert_equal 101, ranks.size
    assert_equal 1, ranks[99]
    assert_equal 2, ranks[100]
  end
end
