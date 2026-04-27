require "csv"

class AddFrequencyRankAndDifficulty < ActiveRecord::Migration[8.0]
  BUCKET_SIZE = 100
  SEED_FILES = %w[common_nouns.csv common_verbs.csv].freeze

  def up
    add_column :cards, :frequency_rank, :integer
    add_index :cards, :frequency_rank

    add_column :quiz_sessions, :difficulty, :integer, default: 0, null: false

    backfill_card_ranks
  end

  def down
    remove_column :quiz_sessions, :difficulty
    remove_index :cards, :frequency_rank
    remove_column :cards, :frequency_rank
  end

  private

  def backfill_card_ranks
    rank_map = build_rank_map
    return if rank_map.empty?

    rank_map.each do |(english, pos), tier|
      execute(<<~SQL.squish)
        UPDATE cards
        SET frequency_rank = #{tier.to_i}
        WHERE english_text = #{quote(english)}
          AND part_of_speech = #{quote(pos)}
      SQL
    end
  end

  def build_rank_map
    seeds_dir = Rails.root.join("db", "seeds")
    map = {}

    SEED_FILES.each do |filename|
      path = seeds_dir.join(filename)
      next unless File.exist?(path)

      CSV.read(path, headers: true).each_with_index do |row, idx|
        english = row["english"].to_s.strip.downcase
        pos = row["part_of_speech"].to_s.strip.downcase.presence || "noun"
        next if english.blank?

        tier = (idx / BUCKET_SIZE) + 1
        map[[english, pos]] ||= tier
      end
    end

    map
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
