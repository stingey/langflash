class QuizQuestionSelector
  FALLBACK_CHOICES = {
    en_to_es: {
      "noun" => [
        "la casa", "el perro", "el gato", "la manzana", "la escuela",
        "el amigo", "el agua", "el sol", "el libro", "la mesa"
      ],
      "verb" => %w[correr comer beber hablar caminar leer escribir dormir cantar mirar]
    },
    es_to_en: {
      "noun" => %w[house dog cat apple school friend water sun book table],
      "verb" => [
        "to run", "to eat", "to drink", "to speak", "to walk",
        "to read", "to write", "to sleep", "to sing", "to watch"
      ]
    }
  }.freeze

  ALLOWED_CATEGORIES = %w[all noun verb].freeze

  def initialize(user:, difficulty: :normal, category: "all")
    @user = user
    @difficulty = difficulty.to_sym
    @category = category.to_s.presence_in(ALLOWED_CATEGORIES) || "all"
    @stats_by_card_id = @user.user_card_stats.index_by(&:card_id)
  end

  def next_card(recent_ids: [], hard_exclude_ids: [])
    scope = @user.cards.where.not(id: hard_exclude_ids)
    scope = scope.where(part_of_speech: @category) unless @category == "all"
    cards = scope.to_a
    cards = restrict_to_hard_pool(cards) if hard_mode?
    return nil if cards.empty?

    recent_ids = recent_ids.map(&:to_i)
    preferred_cards = cards.reject { |card| recent_ids.include?(card.id) }
    pool = preferred_cards.presence || cards

    weighted_sample(pool)
  end

  def choices_for(card:, mode:, count: 4)
    answer_column = mode == "en_to_es" ? :spanish_text : :english_text
    correct_choice = card.public_send(answer_column)

    pool = @user.cards
      .where(part_of_speech: card.part_of_speech)
      .where.not(id: card.id)
      .pluck(answer_column)
    distractors = pool.sample(count - 1).map(&:to_s)
    choices = ([correct_choice.to_s] + distractors).uniq

    fallback_pool = FALLBACK_CHOICES
      .fetch(mode.to_sym, {})
      .fetch(card.part_of_speech, [])
      .dup
      .shuffle
    while choices.size < count && fallback_pool.any?
      candidate = fallback_pool.shift
      choices << candidate unless choices.include?(candidate)
    end

    choices.first(count).shuffle
  end

  private

  def hard_mode?
    @difficulty == :hard
  end

  # In hard mode we narrow the pool to the rarest portion of the user's bank.
  # Cards without a frequency rank (e.g. user-created custom cards) are
  # excluded for now -- they can be revisited later.
  def restrict_to_hard_pool(cards)
    ranked = cards.select { |card| card.frequency_rank.present? }
    return [] if ranked.empty?

    max_tier = ranked.map(&:frequency_rank).max
    threshold = (max_tier / 2.0).ceil
    ranked.select { |card| card.frequency_rank >= threshold }
  end

  def weighted_sample(cards)
    weighted = cards.map { |card| [card, card_weight(card)] }
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

  def card_weight(card)
    base = base_weight(@stats_by_card_id[card.id])
    hard_mode? ? base * rarity_multiplier(card.frequency_rank) : base
  end

  def base_weight(stat)
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

  # Linear boost so rarer tiers within the hard pool dominate. Tier 1 = 1x,
  # each tier above adds 0.2x, capped to keep the most extreme tiers from
  # overwhelming everything else.
  def rarity_multiplier(rank)
    return 1.0 if rank.blank?

    (1.0 + (rank - 1) * 0.2).clamp(1.0, 5.0)
  end

  def rand
    @rand ||= Random.new
    @rand.rand
  end
end
