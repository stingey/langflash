class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :english_text, null: false
      t.string :spanish_text, null: false

      t.timestamps
    end

    add_index :cards, [:user_id, :english_text], unique: true
  end
end
