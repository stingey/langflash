class LeaderboardsController < ApplicationController
  MIN_CARDS_TO_QUALIFY = 100

  def index
    @min_cards = MIN_CARDS_TO_QUALIFY

    @users = User
      .left_joins(:cards, :user_card_stats)
      .select(<<~SQL.squish)
        users.*,
        COUNT(DISTINCT cards.id) AS cards_count,
        COUNT(DISTINCT user_card_stats.id) FILTER (
          WHERE user_card_stats.mastery_score > #{UserCardStat::MASTERY_THRESHOLD}
          AND user_card_stats.total_attempts >= #{UserCardStat::MASTERY_MIN_ATTEMPTS}
        ) AS mastered_count,
        MAX(user_card_stats.last_seen_at) AS last_active_at
      SQL
      .group("users.id")
      .having("COUNT(DISTINCT cards.id) >= ?", MIN_CARDS_TO_QUALIFY)
      .order(Arel.sql("mastered_count DESC, last_active_at DESC NULLS LAST, users.created_at ASC"))
  end
end
