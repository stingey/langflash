require "csv"
require "set"

class CardSeedImporter
  SEEDS_DIR = Rails.root.join("db", "seeds").freeze
  DEFAULT_BATCH_SIZE = 25
  RANK_BUCKET_SIZE = 100

  def self.import(user, csv_filename, batch_size: DEFAULT_BATCH_SIZE)
    new(user, SEEDS_DIR.join(csv_filename)).call(batch_size: batch_size)
  end

  def self.progress(user, csv_filename)
    new(user, SEEDS_DIR.join(csv_filename)).progress
  end

  def initialize(user, csv_path)
    @user = user
    @csv_path = csv_path
  end

  def call(batch_size: DEFAULT_BATCH_SIZE)
    rows = valid_rows
    owned_keys = owned_keys_set
    seed_owned_before = rows.count { |row| owned_keys.include?(key_for(row)) }

    to_create = []
    rows.each do |row|
      next if owned_keys.include?(key_for(row))

      to_create << row
      break if to_create.size >= batch_size
    end

    to_create.each do |row|
      @user.cards.create!(
        english_text: row[:english],
        spanish_text: row[:spanish],
        part_of_speech: row[:part_of_speech],
        frequency_rank: row[:frequency_rank]
      )
    end

    {
      created: to_create.size,
      total_seed: rows.size,
      seed_owned: seed_owned_before + to_create.size
    }
  end

  def progress
    rows = valid_rows
    owned_keys = owned_keys_set
    seed_owned = rows.count { |row| owned_keys.include?(key_for(row)) }

    { total_seed: rows.size, seed_owned: seed_owned }
  end

  private

  def valid_rows
    @valid_rows ||= CSV.read(@csv_path, headers: true).each_with_index.filter_map do |row, idx|
      english = row["english"].to_s.strip.downcase
      spanish = row["spanish"].to_s.strip.downcase
      pos = row["part_of_speech"].to_s.strip.downcase.presence || "noun"
      next if english.blank? || spanish.blank?

      {
        english: english,
        spanish: spanish,
        part_of_speech: pos,
        frequency_rank: (idx / RANK_BUCKET_SIZE) + 1
      }
    end
  end

  def owned_keys_set
    @user.cards.pluck(:english_text, :part_of_speech).to_set
  end

  def key_for(row)
    [row[:english], row[:part_of_speech]]
  end
end
