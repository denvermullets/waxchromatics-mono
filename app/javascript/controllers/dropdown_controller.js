import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()
    const isOpen = !this.menuTarget.classList.contains("hidden")

    // Close all other dropdowns
    document.querySelectorAll('[data-controller="dropdown"] [data-dropdown-target="menu"]').forEach((menu) => {
      if (menu !== this.menuTarget) menu.classList.add("hidden")
    })

    // Toggle this one
    this.menuTarget.classList.toggle("hidden", isOpen)
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}
