class ScopeCardsUniqueIndexByPartOfSpeech < ActiveRecord::Migration[8.0]
  def change
    remove_index :cards, name: "index_cards_on_user_id_and_english_text"
    add_index :cards,
              [:user_id, :english_text, :part_of_speech],
              unique: true,
              name: "index_cards_on_user_id_and_english_text_and_pos"
  end
end
