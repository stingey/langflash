class CreateUserCardStats < ActiveRecord::Migration[8.0]
  def change
    create_table :user_card_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :total_attempts, null: false, default: 0
      t.integer :correct_attempts, null: false, default: 0
      t.integer :incorrect_attempts, null: false, default: 0
      t.integer :streak, null: false, default: 0
      t.float :mastery_score, null: false, default: 0.0
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :user_card_stats, [:user_id, :card_id], unique: true
  end
end
