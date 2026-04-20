#!/usr/bin/env ruby
# frozen_string_literal: true

# One-off script to regenerate db/seeds/common_nouns.csv and common_verbs.csv
# from the doozan/spanish_data dataset (CC-BY-4.0).
#
# Inputs (downloaded to tmp/spanish_data/):
#   - frequency.csv    : frequency-ranked Spanish lemmas with POS tags
#                        (derived from hermitdave/FrequencyWords, CC-BY-SA 3.0)
#   - es-en.data       : Spanish -> English Wiktionary data (CC-BY-SA)
#
# Usage:
#   mkdir -p tmp/spanish_data
#   curl -sL https://raw.githubusercontent.com/doozan/spanish_data/master/frequency.csv \
#     -o tmp/spanish_data/frequency.csv
#   curl -sL https://raw.githubusercontent.com/doozan/spanish_data/master/es-en.data \
#     -o tmp/spanish_data/es-en.data
#   ruby script/build_seed_csvs.rb

require "csv"
require "set"

DATA_DIR   = File.expand_path("../tmp/spanish_data", __dir__)
SEEDS_DIR  = File.expand_path("../db/seeds", __dir__)
TOP_NOUNS  = 2000
TOP_VERBS  = 2000

# Some feminine nouns beginning with a stressed /a/ take "el" in the
# singular (but remain feminine grammatically). This is a small closed
# class; we override article selection for these.
EL_FEMININE_NOUNS = %w[
  agua águila ala alma ama ancla área arma asta aula
  habla hacha hada hambre haya
].to_set

def parse_dictionary(path)
  puts "Parsing dictionary from #{path}..."
  entries = {}
  current_word = nil
  current_sub = nil

  File.foreach(path) do |line|
    line = line.chomp

    if line == "_____"
      current_word = nil
      current_sub = nil
      next
    end

    if current_word.nil?
      current_word = line.strip
      next
    end

    if line.start_with?("pos:")
      pos = line.sub("pos:", "").strip
      entries[current_word] ||= {}
      entries[current_word][pos] ||= []
      current_sub = { gender: nil, glosses: [] }
      entries[current_word][pos] << current_sub
      next
    end

    next if current_sub.nil?

    if line =~ /\A\s*g:\s*(\S+)/
      current_sub[:gender] ||= Regexp.last_match(1)
    elsif line =~ /\A\s*gloss:\s*(.+)/
      current_sub[:glosses] << Regexp.last_match(1).strip
    end
  end

  puts "  Loaded #{entries.size} dictionary entries"
  entries
end

# Rank a sub-entry's quality for learner-friendliness. Lower is better.
def gloss_quality_penalty(sub, spanish_word)
  glosses = sub[:glosses]
  return 1000 if glosses.empty?

  head = glosses.first.to_s.downcase.strip
  stripped = head.gsub(/\([^)]*\)/, " ").squeeze(" ").strip
  penalty = 0
  penalty += 50 if head.match?(/\b(greek|latin|hebrew)?\s?letter\b/)
  penalty += 50 if head.match?(/\bthe symbol\b/)
  penalty += 30 if GLOSS_REJECT_PREFIXES.any? { |bad| head.start_with?("#{bad} ") || head.start_with?("#{bad}:") }
  penalty += 40 if stripped == spanish_word.downcase # gloss == word: jargon (music note "mi", etc.)
  penalty += 10 if stripped.length <= 2
  penalty
end

def clean_gloss(gloss)
  # Strip parenthetical and bracketed qualifiers:
  #   "to be (essentially or identified as)" -> "to be"
  #   "to hope [+direct object or que]"      -> "to hope"
  cleaned = gloss.gsub(/\([^)]*\)/, " ").gsub(/\[[^\]]*\]/, " ").squeeze(" ").strip
  # Take only the primary translation before a comma or semicolon:
  # "man, mankind" -> "man"; "city hall; town hall" -> "city hall"
  cleaned = cleaned.split(/[,;]/).first.to_s.strip
  # Collapse orthographic variants: "favor/favour" -> "favor".
  cleaned = cleaned.split("/").first.to_s.strip
  cleaned.downcase
end

# Prefer glosses that don't lead with a qualifier (archaic, obsolete, etc.)
# or a meta/cross-reference ("translated as...", "alternative form of...",
# "see also..."). Fall back to first.
GLOSS_REJECT_PREFIXES = %w[
  alternative obsolete archaic dated rare colloquial vulgar slang
  translated compare see
 ].freeze

# True if the gloss looks like an incoherent word-soup rather than a
# coherent synonym list. "civility, polity, public order, police,
# fineness, neatness, urbanity" (policía's archaic senses) is a word-soup.
# "police, police department, police force" is NOT — tokens repeat.
def word_soup?(head)
  items = head.split(",").map(&:strip).reject(&:empty?)
  return false if items.length < 6 # conservative threshold; 4-item lists like
                                   # "kind, type, sort, manner" should still pass

  first_tokens = items.first.split(/\s+/)
  return true if first_tokens.empty?

  items[1..].none? { |item| first_tokens.any? { |t| item.include?(t) } }
end

def best_gloss(glosses)
  preferred = glosses.find do |g|
    head = g.to_s.downcase.strip
    head = head.sub(/\A\([^)]*\)\s*/, "") # peel leading parenthetical
    next false if GLOSS_REJECT_PREFIXES.any? { |bad| head.start_with?("#{bad} ") || head.start_with?("#{bad}:") }
    next false if word_soup?(head)

    true
  end
  preferred || glosses.first
end

def article_for_noun(spanish_word, gender)
  base = spanish_word.split(/\s+/).first.to_s.downcase
  return "el" if EL_FEMININE_NOUNS.include?(base)

  case gender
  when "m", "m-p" then "el"
  when "f", "f-p" then "la"
  when "mf", "mfbysense" then "el" # default for common-gender; user can edit
  end
end

def build_nouns(freq_rows, dict)
  rows = []
  seen_english = Set.new

  freq_rows.each do |row|
    break if rows.size >= TOP_NOUNS
    next unless row["pos"] == "n"
    next if row["flags"].to_s.include?("DUPLICATE")

    spanish = row["spanish"].to_s.strip.downcase
    next if spanish.empty? || spanish.match?(/\s/) # skip multiword entries

    sub_entries = dict.dig(spanish, "n") || []
    # Drop plural-only senses (e.g. "gracias" = f-p) — they yield
    # ungrammatical cards like "la gracias".
    sub_entries = sub_entries.reject { |s| %w[m-p f-p].include?(s[:gender]) }
    sub_entries = sub_entries.select { |s| s[:glosses].any? }
    next if sub_entries.empty?

    # Pick the cleanest sense (e.g. music-note "mi" over Greek-letter "mi").
    sub = sub_entries.min_by { |s| gloss_quality_penalty(s, spanish) }
    # If even the cleanest sense is low quality, skip the word entirely
    # (e.g. "mi" whose only noun senses are "the Greek letter mu" and the
    # music-note "mi" itself — no useful learner card here).
    next if gloss_quality_penalty(sub, spanish) >= 40

    article = article_for_noun(spanish, sub[:gender])
    next unless article

    gloss = clean_gloss(best_gloss(sub[:glosses]))
    # Strip a leading "the " since our card already prefixes "el"/"la".
    gloss = gloss.sub(/\Athe\s+/, "")
    next if gloss.empty?
    next if seen_english.include?(gloss)

    seen_english << gloss
    rows << {
      english: gloss,
      spanish: "#{article} #{spanish}",
      part_of_speech: "noun"
    }
  end

  rows
end

def build_verbs(freq_rows, dict)
  rows = []
  seen_english = Set.new

  freq_rows.each do |row|
    break if rows.size >= TOP_VERBS
    next unless row["pos"] == "v"
    next if row["flags"].to_s.include?("DUPLICATE")

    spanish = row["spanish"].to_s.strip.downcase
    next if spanish.empty?
    next unless spanish.match?(/(ar|er|ir|ír)\z/) # only keep infinitives

    sub_entries = (dict.dig(spanish, "v") || []).select { |s| s[:glosses].any? }
    next if sub_entries.empty?

    sub = sub_entries.min_by { |s| gloss_quality_penalty(s, spanish) }
    gloss = clean_gloss(best_gloss(sub[:glosses]))
    next if gloss.empty?

    english = gloss.start_with?("to ") ? gloss : "to #{gloss}"
    next if seen_english.include?(english)

    seen_english << english
    rows << {
      english: english,
      spanish: spanish,
      part_of_speech: "verb"
    }
  end

  rows
end

def write_csv(path, rows)
  CSV.open(path, "w") do |csv|
    csv << %w[english spanish part_of_speech]
    rows.each { |r| csv << [r[:english], r[:spanish], r[:part_of_speech]] }
  end
  puts "Wrote #{rows.size} rows to #{path}"
end

unless File.exist?(File.join(DATA_DIR, "frequency.csv")) &&
       File.exist?(File.join(DATA_DIR, "es-en.data"))
  abort "Missing input files. See usage at the top of this script."
end

freq_rows = CSV.read(File.join(DATA_DIR, "frequency.csv"), headers: true)
puts "Loaded #{freq_rows.size} frequency rows"

dict = parse_dictionary(File.join(DATA_DIR, "es-en.data"))

nouns = build_nouns(freq_rows, dict)
verbs = build_verbs(freq_rows, dict)

write_csv(File.join(SEEDS_DIR, "common_nouns.csv"), nouns)
write_csv(File.join(SEEDS_DIR, "common_verbs.csv"), verbs)

puts "Done."
