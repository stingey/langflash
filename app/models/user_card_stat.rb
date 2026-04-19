class UserCardStat < ApplicationRecord
  MASTERY_THRESHOLD = 90.0
  MASTERY_MIN_ATTEMPTS = 3

  belongs_to :user
  belongs_to :card

  validates :user_id, uniqueness: { scope: :card_id }

  scope :mastered, -> {
    where("mastery_score > ? AND total_attempts >= ?", MASTERY_THRESHOLD, MASTERY_MIN_ATTEMPTS)
  }

  scope :needs_practice, -> {
    where("incorrect_attempts > 0 AND mastery_score < ?", MASTERY_THRESHOLD)
  }

  def record_attempt!(correct:)
    self.total_attempts += 1
    self.last_seen_at = Time.current

    if correct
      self.correct_attempts += 1
      self.streak += 1
    else
      self.incorrect_attempts += 1
      self.streak = 0
    end

    self.mastery_score = if total_attempts.zero?
      0.0
    else
      ((correct_attempts.to_f / total_attempts) * 100).round(1)
    end

    save!
  end
end
