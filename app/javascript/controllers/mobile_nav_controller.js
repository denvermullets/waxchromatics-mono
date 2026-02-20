import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "hamburger", "close"]

  connect() {
    document.addEventListener("turbo:before-visit", this.hide)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.hide)
  }

  toggle() {
    this.drawerTarget.classList.toggle("hidden")
    this.hamburgerTarget.classList.toggle("hidden")
    this.closeTarget.classList.toggle("hidden")
  }

  hide = () => {
    this.drawerTarget.classList.add("hidden")
    this.hamburgerTarget.classList.remove("hidden")
    this.closeTarget.classList.add("hidden")
  }
}
