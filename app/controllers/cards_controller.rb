class CardsController < ApplicationController
  before_action :set_card, only: [:show, :edit, :update, :destroy]

  FILTERS = %w[all nouns verbs mastered needs_practice].freeze

  def index
    @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "all"
    @cards = current_user.cards.order(:english_text)

    case @filter
    when "nouns"
      @cards = @cards.where(part_of_speech: "noun")
    when "verbs"
      @cards = @cards.where(part_of_speech: "verb")
    when "mastered"
      mastered_ids = current_user.user_card_stats.mastered.pluck(:card_id)
      @cards = @cards.where(id: mastered_ids)
    when "needs_practice"
      practice_ids = current_user.user_card_stats.needs_practice.pluck(:card_id)
      @cards = @cards.where(id: practice_ids)
    end
  end

  def show
  end

  def new
    @card = current_user.cards.new
  end

  def create
    @card = current_user.cards.new(card_params)

    if @card.save
      redirect_to new_card_path, notice: "Card created. Add another one!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @card.update(card_params)
      redirect_to @card, notice: "Card updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @card.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(helpers.dom_id(@card)),
          turbo_stream.update("cards-total-count", current_user.cards.count)
        ]
      end
      format.html { redirect_to cards_path, notice: "Card deleted." }
    end
  end

  def translate_suggestion
    suggestion = TranslationService.translate_en_to_es(params[:english_text])
    render json: {
      suggestion: suggestion.to_s,
      available: suggestion.present?
    }
  end

  def import_common_nouns
    result = CommonNounImporter.new(current_user).call
    redirect_to cards_path,
                notice: "Added #{result[:created]} common noun cards (#{result[:skipped]} skipped as duplicates)."
  end

  def import_common_verbs
    result = CommonVerbImporter.new(current_user).call
    redirect_to cards_path,
                notice: "Added #{result[:created]} common verb cards (#{result[:skipped]} skipped as duplicates)."
  end

  private

  def set_card
    @card = current_user.cards.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:english_text, :spanish_text, :part_of_speech)
  end
end
