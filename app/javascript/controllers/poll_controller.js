import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
    active: { type: Boolean, default: true }
  }

  connect() {
    if (this.activeValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.stopPolling()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async poll() {
    try {
      const response = await fetch(window.location.href, {
        headers: { "Accept": "text/html" }
      })
      if (!response.ok) return

      const html = await response.text()
      const doc = new DOMParser().parseFromString(html, "text/html")
      const newRoot = doc.querySelector(`[data-controller~="poll"]`)
      if (!newRoot) return

      // Snapshot open <details> elements by their summary text
      const openDetails = new Set()
      this.element.querySelectorAll("details[open]").forEach(d => {
        openDetails.add(this.#detailsKey(d))
      })

      const scrollY = window.scrollY

      // Replace content without a full Turbo visit
      this.element.innerHTML = newRoot.innerHTML

      // Restore <details> open state
      this.element.querySelectorAll("details").forEach(d => {
        if (openDetails.has(this.#detailsKey(d))) {
          d.setAttribute("open", "")
        } else {
          d.removeAttribute("open")
        }
      })

      window.scrollTo(0, scrollY)

      // Stop polling once the import finishes
      if (newRoot.dataset.pollActiveValue === "false") {
        this.stopPolling()
      }
    } catch {
      // ignore fetch errors silently
    }
  }

  #detailsKey(el) {
    const summary = el.querySelector("summary")
    return summary ? summary.textContent.trim().replace(/\s+/g, " ") : ""
  }
}
