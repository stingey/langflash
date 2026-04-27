class AddCategoryToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_sessions, :category, :string, default: "all", null: false
  end
end
