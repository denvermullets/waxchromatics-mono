import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenField", "selectedName"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.resultsTarget.innerHTML = ""
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 300)
  }

  async fetchResults(query) {
    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
    const response = await fetch(url)
    const artists = await response.json()

    if (artists.length === 0) {
      this.resultsTarget.innerHTML =
        '<div class="px-3 py-2 text-woodsmoke-400 text-sm">No artists found</div>'
      this.resultsTarget.classList.remove("hidden")
      return
    }

    this.resultsTarget.innerHTML = artists
      .map(
        (a) =>
          `<button type="button" class="block w-full text-left px-3 py-2 text-woodsmoke-100 hover:bg-woodsmoke-800 text-sm" data-action="click->artist-search#select" data-artist-id="${a.id}" data-artist-name="${this.escapeHtml(a.name)}">${this.escapeHtml(a.name)}</button>`
      )
      .join("")
    this.resultsTarget.classList.remove("hidden")
  }

  select(event) {
    event.preventDefault()
    const { artistId, artistName } = event.target.dataset

    this.hiddenFieldTarget.value = artistId
    this.selectedNameTarget.textContent = artistName
    this.selectedNameTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
