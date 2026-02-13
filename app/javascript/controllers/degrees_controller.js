import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "inputA", "resultsA", "hiddenA", "selectedNameA", "selectedDisplayA", "searchWrapperA",
    "inputB", "resultsB", "hiddenB", "selectedNameB", "selectedDisplayB", "searchWrapperB",
    "submitBtn", "resultsContainer", "loading"
  ]

  connect() {
    this.timeoutA = null
    this.timeoutB = null
  }

  // ── Search ──

  searchA() {
    clearTimeout(this.timeoutA)
    const query = this.inputATarget.value.trim()
    if (query.length < 2) {
      this.resultsATarget.innerHTML = ""
      this.resultsATarget.classList.add("hidden")
      return
    }
    this.timeoutA = setTimeout(() => this.fetchResults(query, "a"), 300)
  }

  searchB() {
    clearTimeout(this.timeoutB)
    const query = this.inputBTarget.value.trim()
    if (query.length < 2) {
      this.resultsBTarget.innerHTML = ""
      this.resultsBTarget.classList.add("hidden")
      return
    }
    this.timeoutB = setTimeout(() => this.fetchResults(query, "b"), 300)
  }

  async fetchResults(query, side) {
    const url = `/artists/search?q=${encodeURIComponent(query)}`
    const response = await fetch(url)
    const artists = await response.json()
    const resultsEl = side === "a" ? this.resultsATarget : this.resultsBTarget

    if (artists.length === 0) {
      resultsEl.innerHTML = '<div class="px-3 py-2 text-woodsmoke-400 text-sm">No artists found</div>'
      resultsEl.classList.remove("hidden")
      return
    }

    resultsEl.innerHTML = artists
      .map(a =>
        `<button type="button" class="block w-full text-left px-3 py-2 text-woodsmoke-100 hover:bg-woodsmoke-700 text-sm cursor-pointer" data-action="click->degrees#selectArtist" data-side="${side}" data-artist-id="${a.id}" data-artist-name="${this.escapeHtml(a.name)}">${this.escapeHtml(a.name)}</button>`
      )
      .join("")
    resultsEl.classList.remove("hidden")
  }

  // ── Select / Clear ──

  selectArtist(event) {
    event.preventDefault()
    const btn = event.target.closest("[data-artist-id]")
    if (!btn) return

    const { side, artistId, artistName } = btn.dataset
    this.setSelected(side, artistId, artistName)
  }

  setSelected(side, id, name) {
    if (side === "a") {
      this.hiddenATarget.value = id
      this.selectedNameATarget.textContent = name
      this.selectedDisplayATarget.classList.remove("hidden")
      this.selectedDisplayATarget.classList.add("flex")
      this.searchWrapperATarget.classList.add("hidden")
      this.resultsATarget.innerHTML = ""
      this.resultsATarget.classList.add("hidden")
      this.inputATarget.value = ""
    } else {
      this.hiddenBTarget.value = id
      this.selectedNameBTarget.textContent = name
      this.selectedDisplayBTarget.classList.remove("hidden")
      this.selectedDisplayBTarget.classList.add("flex")
      this.searchWrapperBTarget.classList.add("hidden")
      this.resultsBTarget.innerHTML = ""
      this.resultsBTarget.classList.add("hidden")
      this.inputBTarget.value = ""
    }
    this.updateSubmitState()
  }

  clearA(event) {
    event.preventDefault()
    this.hiddenATarget.value = ""
    this.selectedDisplayATarget.classList.add("hidden")
    this.selectedDisplayATarget.classList.remove("flex")
    this.searchWrapperATarget.classList.remove("hidden")
    this.inputATarget.focus()
    this.updateSubmitState()
  }

  clearB(event) {
    event.preventDefault()
    this.hiddenBTarget.value = ""
    this.selectedDisplayBTarget.classList.add("hidden")
    this.selectedDisplayBTarget.classList.remove("flex")
    this.searchWrapperBTarget.classList.remove("hidden")
    this.inputBTarget.focus()
    this.updateSubmitState()
  }

  // ── Swap ──

  swap(event) {
    event.preventDefault()
    const idA = this.hiddenATarget.value
    const nameA = this.selectedNameATarget.textContent
    const hasA = idA !== ""

    const idB = this.hiddenBTarget.value
    const nameB = this.selectedNameBTarget.textContent
    const hasB = idB !== ""

    // Reset both sides
    this.resetSide("a")
    this.resetSide("b")

    // Swap values
    if (hasB) this.setSelected("a", idB, nameB)
    if (hasA) this.setSelected("b", idA, nameA)
  }

  resetSide(side) {
    if (side === "a") {
      this.hiddenATarget.value = ""
      this.selectedNameATarget.textContent = ""
      this.selectedDisplayATarget.classList.add("hidden")
      this.selectedDisplayATarget.classList.remove("flex")
      this.searchWrapperATarget.classList.remove("hidden")
    } else {
      this.hiddenBTarget.value = ""
      this.selectedNameBTarget.textContent = ""
      this.selectedDisplayBTarget.classList.add("hidden")
      this.selectedDisplayBTarget.classList.remove("flex")
      this.searchWrapperBTarget.classList.remove("hidden")
    }
  }

  // ── Submit ──

  updateSubmitState() {
    const ready = this.hiddenATarget.value !== "" && this.hiddenBTarget.value !== ""
    this.submitBtnTarget.disabled = !ready
    if (ready) {
      this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.submitBtnTarget.classList.add("cursor-pointer")
    } else {
      this.submitBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.submitBtnTarget.classList.remove("cursor-pointer")
    }
  }

  async findConnections(event) {
    event.preventDefault()
    const artistAId = this.hiddenATarget.value
    const artistBId = this.hiddenBTarget.value
    if (!artistAId || !artistBId) return

    // Show loading state
    this.loadingTarget.classList.remove("hidden")
    this.resultsContainerTarget.querySelector("#connection-results").innerHTML = ""

    const url = `/connections/search?artist_a_id=${artistAId}&artist_b_id=${artistBId}`
    try {
      const response = await fetch(url, {
        headers: { "Accept": "text/html" }
      })
      const html = await response.text()
      this.loadingTarget.classList.add("hidden")
      this.resultsContainerTarget.innerHTML = html
    } catch {
      this.loadingTarget.classList.add("hidden")
      this.resultsContainerTarget.innerHTML =
        '<div id="connection-results"><p class="text-red-400 text-center py-8">Something went wrong. Please try again.</p></div>'
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
