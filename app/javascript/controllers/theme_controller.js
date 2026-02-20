import { Controller } from "@hotwired/stimulus"

// Updates the body's data-theme attribute when a theme radio is selected.
// Placed on the turbo-frame wrapping the theme cards so it fires after
// Turbo re-renders the frame with the new selection.
export default class extends Controller {
  static values = { current: String }

  currentValueChanged() {
    this.#applyTheme(this.currentValue)
  }

  select(event) {
    this.#applyTheme(event.target.value)
  }

  #applyTheme(theme) {
    if (theme === "ember") {
      delete document.body.dataset.theme
    } else {
      document.body.dataset.theme = theme
    }
  }
}
