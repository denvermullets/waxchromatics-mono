import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chart"]

  toggle(event) {
    const button = event.currentTarget
    const queueIndex = parseInt(button.dataset.queueFilterIndexParam)
    const active = button.dataset.active === "true"

    button.dataset.active = (!active).toString()
    button.style.opacity = active ? "0.3" : "1"

    const chartController = this.application.getControllerForElementAndIdentifier(
      this.chartTarget,
      "chart"
    )

    if (chartController) {
      // Each queue has 2 datasets: enqueued + finished
      const enqueuedIndex = queueIndex * 2
      const finishedIndex = queueIndex * 2 + 1
      chartController.toggle({ params: { index: enqueuedIndex } })
      chartController.toggle({ params: { index: finishedIndex } })
    }
  }
}
