class QuizQuestionSelector
  FALLBACK_CHOICES = {
    en_to_es: %w[casa perro gato manzana escuela amigo agua sol libro mesa],
    es_to_en: %w[house dog cat apple school friend water sun book table]
  }.freeze

  def initialize(user:)
    @user = user
    @stats_by_card_id = @user.user_card_stats.index_by(&:card_id)
  end

  def next_card(recent_ids: [], hard_exclude_ids: [])
    cards = @user.cards.where.not(id: hard_exclude_ids).to_a
    return nil if cards.empty?

    recent_ids = recent_ids.map(&:to_i)
    preferred_cards = cards.reject { |card| recent_ids.include?(card.id) }
    pool = preferred_cards.presence || cards

    weighted_sample(pool)
  end

  def choices_for(card:, mode:, count: 4)
    correct_choice = mode == "en_to_es" ? card.spanish_text : card.english_text
    pool = @user.cards.where.not(id: card.id).pluck(mode == "en_to_es" ? :spanish_text : :english_text)
    distractors = pool.sample(count - 1).map(&:to_s)
    choices = ([correct_choice.to_s] + distractors).uniq

    fallback_pool = FALLBACK_CHOICES.fetch(mode.to_sym).dup.shuffle
    while choices.size < count && fallback_pool.any?
      candidate = fallback_pool.shift
      choices << candidate unless choices.include?(candidate)
    end

    choices.first(count).shuffle
  end

  private

  def weighted_sample(cards)
    weighted = cards.map { |card| [card, card_weight(@stats_by_card_id[card.id])] }
    total_weight = weighted.sum { |(_, weight)| weight }
    return cards.sample if total_weight <= 0

    threshold = rand * total_weight
    running = 0.0
    weighted.each do |(card, weight)|
      running += weight
      return card if running >= threshold
    end

    weighted.last.first
  end

  def card_weight(stat)
    return 4.0 if stat.blank?

    incorrect_boost = stat.incorrect_attempts * 2.0
    low_accuracy_boost = (100 - stat.mastery_score) / 25.0
    streak_penalty = stat.streak * 0.4

    days_since_seen = if stat.last_seen_at.present?
      (Time.zone.today - stat.last_seen_at.to_date).to_i
    else
      3
    end
    overdue_bonus = [days_since_seen, 5].min * 0.35

    raw_weight = 1.0 + incorrect_boost + low_accuracy_boost + overdue_bonus - streak_penalty
    raw_weight.clamp(1.0, 15.0)
  end

  def rand
    @rand ||= Random.new
    @rand.rand
  end
end
