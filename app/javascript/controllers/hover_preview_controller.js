import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.preview = null
    this.onEnter = this.showPreview.bind(this)
    this.onMove = this.movePreview.bind(this)
    this.onLeave = this.removePreview.bind(this)

    this.element.addEventListener("mouseenter", this.onEnter)
    this.element.addEventListener("mousemove", this.onMove)
    this.element.addEventListener("mouseleave", this.onLeave)
  }

  disconnect() {
    this.element.removeEventListener("mouseenter", this.onEnter)
    this.element.removeEventListener("mousemove", this.onMove)
    this.element.removeEventListener("mouseleave", this.onLeave)
    this.removePreview()
  }

  showPreview(event) {
    if (!this.urlValue) return

    this.preview = document.createElement("div")
    this.preview.className =
      "fixed z-50 pointer-events-none rounded-sm border border-woodsmoke-700 shadow-lg overflow-hidden bg-woodsmoke-950"
    this.preview.style.width = "400px"
    this.preview.style.height = "400px"

    const img = document.createElement("img")
    img.src = this.urlValue
    img.className = "w-full h-full object-cover"
    this.preview.appendChild(img)

    document.body.appendChild(this.preview)
    this.positionPreview(event)
  }

  movePreview(event) {
    if (this.preview) this.positionPreview(event)
  }

  positionPreview(event) {
    const offset = 12
    let x = event.clientX + offset
    let y = event.clientY + offset

    if (x + 400 > window.innerWidth) x = event.clientX - 400 - offset
    if (y + 400 > window.innerHeight) y = event.clientY - 400 - offset

    this.preview.style.left = `${x}px`
    this.preview.style.top = `${y}px`
  }

  removePreview() {
    if (this.preview) {
      this.preview.remove()
      this.preview = null
    }
  }
}
