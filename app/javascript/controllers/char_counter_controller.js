import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { max: { type: Number, default: 500 } }

  connect() {
    this.update()
  }

  update() {
    this.counterTarget.textContent = `${this.inputTarget.value.length} / ${this.maxValue}`
  }
}
