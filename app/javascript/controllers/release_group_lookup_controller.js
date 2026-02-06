import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["extraFields"]

  reveal() {
    if (this.hasExtraFieldsTarget) {
      this.extraFieldsTarget.classList.remove("hidden")
    }
  }
}
