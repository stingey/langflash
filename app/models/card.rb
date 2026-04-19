class Card < ApplicationRecord
  belongs_to :user
  has_many :quiz_attempts, dependent: :destroy
  has_one :user_card_stat, dependent: :destroy

  enum :part_of_speech, {
    noun: "noun",
    verb: "verb"
  }

  validates :english_text, :spanish_text, presence: true
  validates :english_text, uniqueness: { scope: [:user_id, :part_of_speech] }
  validates :part_of_speech, inclusion: { in: part_of_speeches.keys }

  before_validation :normalize_text

  private

  def normalize_text
    self.english_text = english_text.to_s.strip.downcase
    self.spanish_text = spanish_text.to_s.strip.downcase
  end
end
