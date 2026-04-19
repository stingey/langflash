class CreateQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_attempts do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.string :prompt_text, null: false
      t.string :correct_choice, null: false
      t.string :selected_choice
      t.boolean :correct, null: false, default: false
      t.integer :position

      t.timestamps
    end

    add_index :quiz_attempts, [:quiz_session_id, :position], unique: true
  end
end
