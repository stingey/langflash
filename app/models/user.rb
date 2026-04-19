class User < ApplicationRecord
  has_many :cards, dependent: :destroy
  has_many :quiz_sessions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :user_card_stats, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def quiz_accuracy
    return 0.0 if quiz_attempts.count.zero?

    (quiz_attempts.where(correct: true).count.to_f / quiz_attempts.count * 100).round(1)
  end
end
