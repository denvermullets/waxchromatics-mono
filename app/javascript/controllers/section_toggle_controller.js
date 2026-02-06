import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "edit", "toggleBtn"]
  static values = { emptyText: { type: String, default: "Nothing added yet." } }

  connect() {
    if (this.hasEditTarget && this.#hasFilledFields()) {
      this.showEdit()
      return
    }
    this.showDisplay()
  }

  toggle() {
    if (this.displayTarget.classList.contains("hidden")) {
      this.showDisplay()
    } else {
      this.showEdit()
    }
  }

  showDisplay() {
    this.#buildSummary()
    this.displayTarget.classList.remove("hidden")
    this.editTarget.classList.add("hidden")
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.textContent = "Edit"
    }
  }

  showEdit() {
    this.displayTarget.classList.add("hidden")
    this.editTarget.classList.remove("hidden")
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.textContent = "Done"
    }
  }

  #hasFilledFields() {
    return Array.from(
      this.editTarget.querySelectorAll("input:not([type=hidden]), select, textarea")
    ).some((el) => {
      if (el.tagName === "SELECT") return el.value !== ""
      return el.value && el.value.trim() !== ""
    })
  }

  #buildSummary() {
    const rows = this.editTarget.querySelectorAll("[data-nested-form-row]")
    if (rows.length > 0) {
      this.#buildNestedSummary(rows)
    } else {
      this.#buildFieldSummary()
    }
  }

  #buildNestedSummary(rows) {
    const items = []
    rows.forEach((row) => {
      if (row.classList.contains("hidden")) return
      const destroyInput = row.querySelector("input[name*='_destroy']")
      if (destroyInput && destroyInput.value === "1") return

      const parts = []
      row.querySelectorAll("input:not([type=hidden]), select, textarea").forEach((field) => {
        let val
        if (field.tagName === "SELECT") {
          if (field.value) {
            val = field.options[field.selectedIndex]?.text
          }
        } else {
          val = field.value
        }
        if (val && val.trim()) {
          parts.push(val.trim())
        }
      })
      if (parts.length > 0) items.push(parts.join(" \u2014 "))
    })

    if (items.length === 0) {
      this.displayTarget.innerHTML = `<p class="text-sm text-woodsmoke-400">${this.#escapeHtml(this.emptyTextValue)}</p>`
    } else {
      const listHtml = items
        .map(
          (text) =>
            `<li class="py-1.5 text-sm text-woodsmoke-200">${this.#escapeHtml(text)}</li>`
        )
        .join("")
      this.displayTarget.innerHTML = `<ul class="divide-y divide-woodsmoke-800">${listHtml}</ul>`
    }
  }

  #buildFieldSummary() {
    const fields = this.editTarget.querySelectorAll(
      "input:not([type=hidden]), select, textarea"
    )
    if (fields.length === 0) return

    const rowsHtml = Array.from(fields)
      .map((field) => {
        const wrapper = field.closest("div")
        const label = wrapper?.querySelector("label")
        const labelText = label ? label.textContent.trim() : field.name
        const val = field.value?.trim() || "--"
        return `<tr><td class="py-2 text-woodsmoke-400 w-1/3">${this.#escapeHtml(labelText)}</td><td class="py-2 text-woodsmoke-200">${this.#escapeHtml(val)}</td></tr>`
      })
      .join("")

    this.displayTarget.innerHTML = `<table class="w-full text-sm"><tbody class="divide-y divide-woodsmoke-800">${rowsHtml}</tbody></table>`
  }

  #escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
