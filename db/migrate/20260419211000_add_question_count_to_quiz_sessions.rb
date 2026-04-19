class AddQuestionCountToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_sessions, :question_count, :integer, null: false, default: 10
  end
end
