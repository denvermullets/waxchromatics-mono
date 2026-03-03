import { Controller } from "@hotwired/stimulus"

const ACCENT = { colorClass: "text-crusta-400", btnBg: "var(--color-crusta-400)", btnText: "var(--color-woodsmoke-950)" }

const PREFIXES = {
  "artist:":  { label: "ARTIST",  type: "artist",  plural: "artists",    ...ACCENT },
  "album:":   { label: "ALBUM",   type: "album",   plural: "albums",     ...ACCENT },
  "label:":   { label: "LABEL",   type: "label",   plural: "labels",     ...ACCENT },
  "cat#:":    { label: "CAT#",    type: "cat",     plural: "catalog #s", ...ACCENT },
  "barcode:": { label: "BARCODE", type: "barcode", plural: "barcodes",   ...ACCENT },
  "credit:":  { label: "CREDIT",  type: "credit",  plural: "credits",    ...ACCENT },
}

const DEFAULT_HINT = `<span class="text-woodsmoke-500">&#9679;</span> Default: searching <span class="text-crusta-400">artists</span> &middot; Type a prefix like <span class="text-crusta-400">label:</span> to switch`

export default class extends Controller {
  static targets = ["input", "badge", "badgeText", "hint", "searchBar", "submitBtn"]

  connect() {
    this.currentType = null
    this.activePrefix = null
    this.prefixConfig = null
    this.detect()
  }

  detect() {
    // Already in prefix mode — just update the hint
    if (this.activePrefix) {
      this.updateHint()
      return
    }

    const value = this.inputTarget.value.toLowerCase()
    let matched = null

    for (const [prefix, config] of Object.entries(PREFIXES)) {
      if (value.startsWith(prefix)) {
        matched = { prefix, ...config }
        break
      }
    }

    if (matched) {
      // Strip the prefix from the input, keep only the search term
      const remaining = this.inputTarget.value.slice(matched.prefix.length).trimStart()
      this.inputTarget.value = remaining
      this.activePrefix = matched.prefix
      this.activate(matched)
    }
  }

  activate({ prefix, label, type, plural, colorClass, btnBg, btnText }) {
    this.currentType = type
    this.prefixConfig = { prefix, label, type, plural, colorClass, btnBg, btnText }

    // Badge
    this.badgeTextTarget.textContent = label
    this.badgeTarget.dataset.active = ""
    this.badgeTarget.dataset.searchType = type

    // Search bar border
    this.searchBarTarget.dataset.type = type

    // Submit button color
    this.submitBtnTarget.style.backgroundColor = btnBg
    this.submitBtnTarget.style.color = btnText

    this.updateHint()
  }

  updateHint() {
    if (!this.prefixConfig) return
    const { colorClass, plural } = this.prefixConfig

    const rawTerm = this.inputTarget.value.trim()
    const safeTerm = rawTerm.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
    const hintHTML = rawTerm
      ? `<span class="${colorClass}">&#9679;</span> Searching <span class="${colorClass}">${plural}</span> for &ldquo;${safeTerm}&rdquo;`
      : `<span class="${colorClass}">&#9679;</span> Searching <span class="${colorClass}">${plural}</span>&hellip;`
    this.hintTarget.innerHTML = hintHTML
  }

  deactivate() {
    if (this.currentType === null) return
    this.currentType = null
    this.activePrefix = null
    this.prefixConfig = null

    delete this.badgeTarget.dataset.active
    delete this.badgeTarget.dataset.searchType
    delete this.searchBarTarget.dataset.type

    // Reset submit button to default orange
    this.submitBtnTarget.style.backgroundColor = ""
    this.submitBtnTarget.style.color = ""

    this.hintTarget.innerHTML = DEFAULT_HINT
  }

  handleKeydown(event) {
    if (event.key === "Backspace" && this.activePrefix && this.inputTarget.value === "") {
      event.preventDefault()
      this.deactivate()
    }
  }

  submit() {
    const term = this.inputTarget.value
    // Prepend the prefix back so the server receives the full query
    if (this.activePrefix) {
      this.inputTarget.value = this.activePrefix + " " + term
    }
    this.inputTarget.blur()
    // Restore clean value after Turbo captures form data
    if (this.activePrefix) {
      requestAnimationFrame(() => { this.inputTarget.value = term })
    }
  }

  insertPrefix(event) {
    event.preventDefault()
    const prefix = event.currentTarget.dataset.prefix
    const config = PREFIXES[prefix]
    if (config) {
      this.activePrefix = prefix
      this.inputTarget.value = ""
      this.activate({ prefix, ...config })
    }
    this.inputTarget.focus()
  }
}
