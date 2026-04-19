class CreateQuizSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :mode, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
