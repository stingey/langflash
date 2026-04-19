class AddPartOfSpeechToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :part_of_speech, :string, null: false, default: "noun"
    add_index :cards, :part_of_speech
  end
end
