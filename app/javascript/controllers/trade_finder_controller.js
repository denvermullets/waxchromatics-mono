import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["matchContent", "matchIcon"]

  toggle(event) {
    const index = event.currentTarget.dataset.index
    const content = this.matchContentTargets[index]
    const icon = this.matchIconTargets[index]

    if (!content) return

    const isOpen = !content.classList.contains("hidden")

    // Close all
    this.matchContentTargets.forEach((el, i) => {
      el.classList.add("hidden")
      if (this.matchIconTargets[i]) {
        this.matchIconTargets[i].classList.remove("rotate-180")
      }
    })

    // Toggle clicked one (if it was closed, open it)
    if (!isOpen) {
      content.classList.remove("hidden")
      if (icon) icon.classList.add("rotate-180")
    }
  }
}
