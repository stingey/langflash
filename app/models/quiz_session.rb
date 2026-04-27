class QuizSession < ApplicationRecord
  belongs_to :user
  has_many :quiz_attempts, dependent: :destroy

  enum :mode, { en_to_es: 0, es_to_en: 1 }
  enum :difficulty, { normal: 0, hard: 1 }
  enum :category, { all: "all", noun: "noun", verb: "verb" }, prefix: :category

  ALLOWED_QUESTION_COUNTS = [10, 25, 50].freeze
  ALLOWED_DIFFICULTIES = %w[normal hard].freeze
  ALLOWED_CATEGORIES = %w[all noun verb].freeze

  validates :mode, presence: true
  validates :started_at, presence: true
  validates :question_count, inclusion: { in: ALLOWED_QUESTION_COUNTS }
  validates :difficulty, inclusion: { in: ALLOWED_DIFFICULTIES }
  validates :category, inclusion: { in: ALLOWED_CATEGORIES }

  scope :completed, -> { where.not(completed_at: nil) }
end
