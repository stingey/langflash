class QuizSession < ApplicationRecord
  belongs_to :user
  has_many :quiz_attempts, dependent: :destroy

  enum :mode, { en_to_es: 0, es_to_en: 1 }

  ALLOWED_QUESTION_COUNTS = [10, 25, 50].freeze

  validates :mode, presence: true
  validates :started_at, presence: true
  validates :question_count, inclusion: { in: ALLOWED_QUESTION_COUNTS }

  scope :completed, -> { where.not(completed_at: nil) }
end
