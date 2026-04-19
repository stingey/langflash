require "csv"

class CardSeedImporter
  SEEDS_DIR = Rails.root.join("db", "seeds").freeze

  def self.import(user, csv_filename)
    new(user, SEEDS_DIR.join(csv_filename)).call
  end

  def initialize(user, csv_path)
    @user = user
    @csv_path = csv_path
  end

  def call
    rows = CSV.read(@csv_path, headers: true)
    created_count = 0
    skipped_count = 0

    rows.each do |row|
      english = row["english"].to_s.strip.downcase
      spanish = row["spanish"].to_s.strip.downcase
      part_of_speech = row["part_of_speech"].to_s.strip.downcase.presence || "noun"

      next if english.blank? || spanish.blank?

      if @user.cards.exists?(english_text: english, part_of_speech: part_of_speech)
        skipped_count += 1
        next
      end

      @user.cards.create!(
        english_text: english,
        spanish_text: spanish,
        part_of_speech: part_of_speech
      )
      created_count += 1
    end

    { created: created_count, skipped: skipped_count }
  end
end
