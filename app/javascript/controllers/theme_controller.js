import { Controller } from "@hotwired/stimulus"

// Updates the body's data-theme attribute when a theme radio is selected.
// Placed on the turbo-frame wrapping the theme cards so it fires after
// Turbo re-renders the frame with the new selection.
export default class extends Controller {
  static values = { current: String }

  currentValueChanged() {
    if (this.currentValue === "ember") {
      delete document.body.dataset.theme
    } else {
      document.body.dataset.theme = this.currentValue
    }
  }
}
