import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      { rootMargin: "-20% 0px -70% 0px" }
    )

    document.querySelectorAll("[data-settings-section]").forEach((section) => {
      this.observer.observe(section)
    })
  }

  disconnect() {
    this.observer.disconnect()
  }

  handleIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const id = entry.target.id
        this.highlightLink(id)
      }
    })
  }

  highlightLink(sectionId) {
    this.linkTargets.forEach((link) => {
      if (link.getAttribute("href") === `#${sectionId}`) {
        link.classList.add("bg-crusta-400", "text-woodsmoke-950", "font-semibold")
        link.classList.remove("text-woodsmoke-400", "hover:text-woodsmoke-50", "hover:bg-woodsmoke-800")
      } else {
        link.classList.remove("bg-crusta-400", "text-woodsmoke-950", "font-semibold")
        link.classList.add("text-woodsmoke-400", "hover:text-woodsmoke-50", "hover:bg-woodsmoke-800")
      }
    })
  }
}
