import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pill", "detail"]

  select(event) {
    const index = event.currentTarget.dataset.edgeIndex

    // Toggle pills
    this.pillTargets.forEach((pill) => {
      if (pill.dataset.edgeIndex === index) {
        pill.classList.add("border-crusta-400", "text-crusta-400")
        pill.classList.remove("border-woodsmoke-700", "text-woodsmoke-300")
      } else {
        pill.classList.remove("border-crusta-400", "text-crusta-400")
        pill.classList.add("border-woodsmoke-700", "text-woodsmoke-300")
      }
    })

    // Toggle detail panels
    this.detailTargets.forEach((panel) => {
      if (panel.dataset.edgeIndex === index && panel.classList.contains("hidden")) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
