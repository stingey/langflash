#!/usr/bin/env ruby
# One-off restore script. Reads from storage/development.sqlite3 and copies
# users + cards + user_card_stats + quiz_sessions + quiz_attempts into the
# current Rails database (Postgres). Idempotent: skips records that already
# exist (matched by email for users, by english_text+part_of_speech per user
# for cards). Run with: bin/rails runner script/restore_from_sqlite.rb
require "sqlite3"

SQLITE_PATH = Rails.root.join("storage", "development.sqlite3").to_s
abort "SQLite file not found at #{SQLITE_PATH}" unless File.exist?(SQLITE_PATH)

db = SQLite3::Database.new(SQLITE_PATH)
db.results_as_hash = true

puts "Restoring from #{SQLITE_PATH}..."

user_id_map = {}

db.execute("SELECT * FROM users").each do |row|
  user = User.find_by(email: row["email"])
  if user
    puts "  user #{row["email"]} already exists (id=#{user.id})"
  else
    user = User.new(email: row["email"])
    %w[
      encrypted_password reset_password_token reset_password_sent_at
      remember_created_at created_at updated_at
    ].each { |attr| user[attr] = row[attr] }
    user.save!(validate: false)
    puts "  created user #{user.email} (id=#{user.id})"
  end
  user_id_map[row["id"]] = user.id
end

card_id_map = {}

db.execute("SELECT * FROM cards").each do |row|
  new_user_id = user_id_map[row["user_id"]]
  next unless new_user_id

  card = Card.find_or_initialize_by(
    user_id: new_user_id,
    english_text: row["english_text"],
    part_of_speech: row["part_of_speech"] || "noun"
  )
  card.spanish_text = row["spanish_text"]
  card.created_at ||= row["created_at"]
  card.updated_at ||= row["updated_at"]
  card.save!
  card_id_map[row["id"]] = card.id
end
puts "  cards: #{card_id_map.size} processed"

stat_count = 0
db.execute("SELECT * FROM user_card_stats").each do |row|
  new_user_id = user_id_map[row["user_id"]]
  new_card_id = card_id_map[row["card_id"]]
  next unless new_user_id && new_card_id

  stat = UserCardStat.find_or_initialize_by(user_id: new_user_id, card_id: new_card_id)
  %w[
    total_attempts correct_attempts incorrect_attempts streak mastery_score
    last_seen_at created_at updated_at
  ].each { |attr| stat[attr] = row[attr] }
  stat.save!
  stat_count += 1
end
puts "  user_card_stats: #{stat_count} processed"

session_id_map = {}
db.execute("SELECT * FROM quiz_sessions").each do |row|
  new_user_id = user_id_map[row["user_id"]]
  next unless new_user_id

  session = QuizSession.create!(
    user_id: new_user_id,
    mode: row["mode"],
    started_at: row["started_at"],
    completed_at: row["completed_at"],
    question_count: row["question_count"] || 10,
    created_at: row["created_at"],
    updated_at: row["updated_at"]
  )
  session_id_map[row["id"]] = session.id
end
puts "  quiz_sessions: #{session_id_map.size} created"

attempt_count = 0
db.execute("SELECT * FROM quiz_attempts").each do |row|
  new_user_id = user_id_map[row["user_id"]]
  new_card_id = card_id_map[row["card_id"]]
  new_session_id = session_id_map[row["quiz_session_id"]]
  next unless new_user_id && new_card_id && new_session_id

  QuizAttempt.create!(
    user_id: new_user_id,
    card_id: new_card_id,
    quiz_session_id: new_session_id,
    prompt_text: row["prompt_text"],
    correct_choice: row["correct_choice"],
    selected_choice: row["selected_choice"],
    correct: row["correct"] == 1 || row["correct"] == true,
    position: row["position"],
    created_at: row["created_at"],
    updated_at: row["updated_at"]
  )
  attempt_count += 1
end
puts "  quiz_attempts: #{attempt_count} created"

puts "Done."
