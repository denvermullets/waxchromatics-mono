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
    this.detect()
  }

  detect() {
    const value = this.inputTarget.value.toLowerCase()
    let matched = null

    for (const [prefix, config] of Object.entries(PREFIXES)) {
      if (value.startsWith(prefix)) {
        matched = { prefix, ...config }
        break
      }
    }

    if (matched) {
      this.activate(matched)
    } else {
      this.deactivate()
    }
  }

  activate({ prefix, label, type, plural, colorClass, btnBg, btnText }) {
    this.currentType = type

    // Badge
    this.badgeTextTarget.textContent = label
    this.badgeTarget.dataset.active = ""
    this.badgeTarget.dataset.searchType = type

    // Search bar border
    this.searchBarTarget.dataset.type = type

    // Submit button color
    this.submitBtnTarget.style.backgroundColor = btnBg
    this.submitBtnTarget.style.color = btnText

    // Hint text with colored spans
    const rawTerm = this.inputTarget.value.slice(prefix.length).trim()
    const safeTerm = rawTerm.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
    const hintHTML = rawTerm
      ? `<span class="${colorClass}">&#9679;</span> Searching <span class="${colorClass}">${plural}</span> for &ldquo;${safeTerm}&rdquo;`
      : `<span class="${colorClass}">&#9679;</span> Searching <span class="${colorClass}">${plural}</span>&hellip;`
    this.hintTarget.innerHTML = hintHTML
  }

  deactivate() {
    if (this.currentType === null) return
    this.currentType = null

    delete this.badgeTarget.dataset.active
    delete this.badgeTarget.dataset.searchType
    delete this.searchBarTarget.dataset.type

    // Reset submit button to default orange
    this.submitBtnTarget.style.backgroundColor = ""
    this.submitBtnTarget.style.color = ""

    this.hintTarget.innerHTML = DEFAULT_HINT
  }

  submit() {
    this.inputTarget.blur()
  }

  insertPrefix(event) {
    event.preventDefault()
    const prefix = event.currentTarget.dataset.prefix
    this.inputTarget.value = prefix + " "
    this.inputTarget.focus()
    this.detect()
  }
}
