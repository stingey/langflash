import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "englishInput",
    "spanishInput",
    "translationHint",
    "suggestionList"
  ]

  connect() {
    this.translationTimer = null
    this.lastSuggestion = ""
    this.lastRequestId = 0
  }

  englishChanged() {
    clearTimeout(this.translationTimer)
    if (!this.englishInputTarget.value.trim()) {
      this.clearSuggestionState()
      return
    }
    this.translationTimer = setTimeout(() => this.fetchSuggestions(), 450)
  }

  async fetchSuggestions() {
    const word = this.englishInputTarget.value.trim()
    if (!word) {
      this.clearSuggestionState()
      return
    }

    const requestId = ++this.lastRequestId
    const response = await fetch(`/cards/translate_suggestion?english_text=${encodeURIComponent(word)}`)
    const data = await response.json()
    if (requestId !== this.lastRequestId) return

    const suggestion = (data.suggestion || "").trim()

    this.suggestionListTarget.innerHTML = ""
    if (!suggestion) {
      this.clearSuggestionState("No translation suggestion available right now.")
      return
    }

    const option = document.createElement("option")
    option.value = suggestion
    this.suggestionListTarget.appendChild(option)

    this.translationHintTarget.textContent = `Suggestion: ${suggestion}`
    this.translationHintTarget.dataset.suggestion = suggestion

    const currentSpanish = this.spanishInputTarget.value.trim().toLowerCase()
    const previousSuggestion = this.lastSuggestion.toLowerCase()
    if (!currentSpanish || currentSpanish === previousSuggestion) {
      this.spanishInputTarget.value = suggestion
    }
    this.lastSuggestion = suggestion
  }

  acceptSuggestion(event) {
    const suggestion = this.translationHintTarget.dataset.suggestion
    if (!suggestion) return

    if (event) event.preventDefault()
    this.spanishInputTarget.value = suggestion
    this.spanishInputTarget.blur()
  }

  clearSuggestionState(message = "") {
    this.translationHintTarget.textContent = message
    this.translationHintTarget.dataset.suggestion = ""
    this.suggestionListTarget.innerHTML = ""
    this.lastSuggestion = ""
  }
}
