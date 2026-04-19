require "json"
require "net/http"

class TranslationService
  ENDPOINT = "https://api.mymemory.translated.net/get".freeze

  def self.translate_en_to_es(text)
    return nil if text.blank?

    query_text = contextual_query(text.to_s.strip)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(q: query_text, langpair: "en|es")

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    translated = body.dig("responseData", "translatedText")
    normalize_translation(translated)
  rescue StandardError => e
    Rails.logger.warn("Translation failed: #{e.message}")
    nil
  end

  def self.contextual_query(text)
    clean_text = text.to_s.strip
    return clean_text unless clean_text.match?(/\A[a-zA-Z]+\z/)

    "the #{clean_text.downcase}"
  end

  def self.normalize_translation(value)
    value.to_s.strip.downcase.delete(".").squeeze(" ").strip.presence
  end
end
