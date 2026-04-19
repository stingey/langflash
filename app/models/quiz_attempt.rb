class QuizAttempt < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :user
  belongs_to :card

  validates :prompt_text, :correct_choice, presence: true
  validates :position, presence: true
end
