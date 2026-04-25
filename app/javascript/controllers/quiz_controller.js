import { Controller } from "@hotwired/stimulus"

// Adds a brief press animation on the chosen answer and a quick fade-out
// before navigating to the next question, so the transition feels less abrupt.
export default class extends Controller {
  static values = {
    pressDelay: { type: Number, default: 90 },
    submitDelay: { type: Number, default: 180 }
  }

  press(event) {
    const button = event.currentTarget
    const form = button.closest("form")
    if (!form || form.dataset.quizSubmitted === "true") {
      return
    }

    if (this.prefersReducedMotion()) {
      this.disableOtherButtons(button)
      button.classList.add("is-pressed")
      form.dataset.quizSubmitted = "true"
      return
    }

    event.preventDefault()
    form.dataset.quizSubmitted = "true"
    button.classList.add("is-pressed")
    this.disableOtherButtons(button)

    window.setTimeout(() => {
      this.element.classList.add("is-leaving")
    }, this.pressDelayValue)

    window.setTimeout(() => {
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit()
      } else {
        form.submit()
      }
    }, this.submitDelayValue)
  }

  disableOtherButtons(activeButton) {
    this.element.querySelectorAll(".choice-button").forEach((btn) => {
      if (btn !== activeButton) {
        btn.disabled = true
      }
    })
  }

  prefersReducedMotion() {
    return window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
