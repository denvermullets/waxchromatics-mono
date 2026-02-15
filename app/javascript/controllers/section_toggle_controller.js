import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "edit", "toggleBtn"];
  static values = {
    emptyText: { type: String, default: "Nothing added yet." },
    format: { type: String, default: "list" },
  };

  connect() {
    if (this.hasEditTarget && this.#hasFilledFields()) {
      this.showEdit();
      return;
    }
    this.showDisplay();
  }

  toggle() {
    if (this.displayTarget.classList.contains("hidden")) {
      this.showDisplay();
    } else {
      this.showEdit();
    }
  }

  showDisplay() {
    this.#buildSummary();
    this.displayTarget.classList.remove("hidden");
    this.editTarget.classList.add("hidden");
    this.toggleBtnTargets.forEach((btn) => (btn.textContent = "Edit"));
  }

  showEdit() {
    this.displayTarget.classList.add("hidden");
    this.editTarget.classList.remove("hidden");
    this.toggleBtnTargets.forEach((btn) => (btn.textContent = "Done"));
  }

  #hasFilledFields() {
    return Array.from(
      this.editTarget.querySelectorAll("input:not([type=hidden]), select, textarea")
    ).some((el) => {
      if (el.tagName === "SELECT") return el.value !== "";
      return el.value && el.value.trim() !== "";
    });
  }

  #buildSummary() {
    const rows = this.editTarget.querySelectorAll("[data-nested-form-row]");
    if (rows.length > 0) {
      this.#buildNestedSummary(rows);
    } else {
      this.#buildFieldSummary();
    }
  }

  // --- Helpers ---

  #visibleRows(allRows) {
    return Array.from(allRows).filter((row) => {
      if (row.classList.contains("hidden")) return false;
      const d = row.querySelector("input[name*='_destroy']");
      return !(d && d.value === "1");
    });
  }

  #rowValues(row) {
    const vals = {};
    row.querySelectorAll("input:not([type=hidden]), select, textarea").forEach((field) => {
      const label = field.closest("div")?.querySelector("label");
      const key = label ? label.textContent.trim().toLowerCase() : "";
      let val;
      if (field.tagName === "SELECT") {
        val = field.value ? field.options[field.selectedIndex]?.text || "" : "";
      } else {
        val = field.value?.trim() || "";
      }
      if (key) vals[key] = val;
    });
    return vals;
  }

  #esc(text) {
    const d = document.createElement("div");
    d.textContent = text;
    return d.innerHTML;
  }

  #empty(text) {
    return `<p class="text-sm text-woodsmoke-500">${this.#esc(text || this.emptyTextValue)}</p>`;
  }

  // --- Nested summary dispatch ---

  #buildNestedSummary(allRows) {
    const rows = this.#visibleRows(allRows);
    switch (this.formatValue) {
      case "tracklist":
        return this.#summaryTracklist(rows);
      case "credits":
        return this.#summaryCredits(rows);
      case "identifiers":
        return this.#summaryIdentifiers(rows);
      case "formats":
        return this.#summaryFormats(rows);
      case "labels":
        return this.#summaryLabels(rows);
      default:
        return this.#summaryGeneric(rows);
    }
  }

  // --- Tracklist: position | title | duration ---

  #summaryTracklist(rows) {
    const items = rows.map((r) => this.#rowValues(r)).filter((v) => v.title || v.position);
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
      return;
    }
    const html = items
      .map(
        (v) => `
      <div class="flex items-center gap-3 py-2 text-sm border-b border-woodsmoke-800 last:border-b-0">
        <span class="shrink-0 w-8 text-woodsmoke-500 text-right">${this.#esc(v.position || "")}</span>
        <span class="flex-1 text-woodsmoke-100 truncate">${this.#esc(v.title || "\u2014")}</span>
        ${v.duration ? `<span class="shrink-0 text-woodsmoke-500">${this.#esc(v.duration)}</span>` : ""}
      </div>`
      )
      .join("");
    this.displayTarget.innerHTML = `<div class="space-y-1">${html}</div>`;
  }

  // --- Credits: role | artist name ---

  #summaryCredits(rows) {
    const items = rows.map((r) => this.#rowValues(r)).filter((v) => v.artist || v.role);
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
      return;
    }
    const html = items
      .map(
        (v) => `
      <div class="flex items-baseline justify-between gap-4 py-3 first:pt-0 last:pb-0">
        <span class="text-sm text-woodsmoke-400">${this.#esc(v.role || "\u2014")}</span>
        <span class="text-sm text-crusta-400 shrink-0">${this.#esc(v.artist || "\u2014")}</span>
      </div>`
      )
      .join("");
    this.displayTarget.innerHTML = `<div class="divide-y divide-woodsmoke-800">${html}</div>`;
  }

  // --- Identifiers: type label + monospace value box ---

  #summaryIdentifiers(rows) {
    const items = rows.map((r) => this.#rowValues(r)).filter((v) => v.value || v.type);
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
      return;
    }
    const html = items
      .map(
        (v) => `
      <div>
        ${v.type ? `<span class="text-xs text-woodsmoke-500 block mb-1">${this.#esc(v.type)}</span>` : ""}
        <div class="px-4 py-3 rounded-sm border border-woodsmoke-700 bg-woodsmoke-950">
          <span class="text-sm text-woodsmoke-300 font-mono break-all">${this.#esc(v.value || "\u2014")}</span>
        </div>
        ${v.description ? `<span class="text-xs text-woodsmoke-500 mt-1 block">${this.#esc(v.description)}</span>` : ""}
      </div>`
      )
      .join("");
    this.displayTarget.innerHTML = `<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">${html}</div>`;
  }

  // --- Formats: badge pills ---

  #summaryFormats(rows) {
    const items = rows.map((r) => this.#rowValues(r)).filter((v) => v.name);
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
      return;
    }
    const badges = items.flatMap((v) => {
      const qty = v.qty && parseInt(v.qty) > 1 ? `${parseInt(v.qty)}\u00d7 ` : "";
      const parts = [qty + v.name];
      if (v.descriptions)
        parts.push(
          ...v.descriptions
            .split(";")
            .map((s) => s.trim())
            .filter(Boolean)
        );
      if (v.color) parts.push(v.color);
      return parts;
    });
    const html = badges
      .map(
        (b) =>
          `<span class="px-2.5 py-1 text-xs font-medium rounded bg-crusta-900/30 text-crusta-400">${this.#esc(b)}</span>`
      )
      .join("");
    this.displayTarget.innerHTML = `<div class="flex flex-wrap gap-2">${html}</div>`;
  }

  // --- Labels: label / catalog # in info-table row style ---

  #summaryLabels(rows) {
    const items = rows.map((r) => this.#rowValues(r)).filter((v) => v.label || v["catalog #"]);
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
      return;
    }
    const html = items
      .map(
        (v) => `
      <div class="grid grid-cols-2 divide-x divide-woodsmoke-800">
        <div class="flex items-baseline justify-between gap-2 px-5 py-3">
          <span class="text-sm text-woodsmoke-400">Label</span>
          <span class="text-sm text-woodsmoke-50 font-medium">${this.#esc(v.label || "\u2014")}</span>
        </div>
        <div class="flex items-baseline justify-between gap-2 px-5 py-3">
          <span class="text-sm text-woodsmoke-400">Catalog #</span>
          <span class="text-sm text-crusta-400 font-medium">${this.#esc(v["catalog #"] || "\u2014")}</span>
        </div>
      </div>`
      )
      .join('<div class="border-t border-woodsmoke-800"></div>');
    this.displayTarget.innerHTML = html;
  }

  // --- Generic list (fallback) ---

  #summaryGeneric(rows) {
    const items = [];
    rows.forEach((row) => {
      const parts = [];
      row.querySelectorAll("input:not([type=hidden]), select, textarea").forEach((field) => {
        let val;
        if (field.tagName === "SELECT") {
          if (field.value) val = field.options[field.selectedIndex]?.text;
        } else {
          val = field.value;
        }
        if (val && val.trim()) parts.push(val.trim());
      });
      if (parts.length > 0) items.push(parts.join(" \u2014 "));
    });
    if (items.length === 0) {
      this.displayTarget.innerHTML = this.#empty();
    } else {
      const html = items
        .map((t) => `<li class="py-1.5 text-sm text-woodsmoke-200">${this.#esc(t)}</li>`)
        .join("");
      this.displayTarget.innerHTML = `<ul class="divide-y divide-woodsmoke-800">${html}</ul>`;
    }
  }

  // --- Field summary (info table style, for non-nested sections) ---

  #buildFieldSummary() {
    const fields = this.editTarget.querySelectorAll("input:not([type=hidden]), select, textarea");
    if (fields.length === 0) return;

    const pairs = [];
    Array.from(fields).forEach((field) => {
      const wrapper = field.closest("div");
      const label = wrapper?.querySelector("label");
      const labelText = label ? label.textContent.trim() : "";
      const val = field.value?.trim() || "\u2014";
      pairs.push({ label: labelText, value: val });
    });

    const gridRows = [];
    for (let i = 0; i < pairs.length; i += 2) {
      const left = pairs[i];
      const right = pairs[i + 1];
      let row = '<div class="grid grid-cols-2 divide-x divide-woodsmoke-800">';
      row += `<div class="flex items-baseline justify-between gap-2 px-5 py-3"><span class="text-sm text-woodsmoke-400">${this.#esc(left.label)}</span><span class="text-sm text-woodsmoke-50 font-medium">${this.#esc(left.value)}</span></div>`;
      if (right) {
        row += `<div class="flex items-baseline justify-between gap-2 px-5 py-3"><span class="text-sm text-woodsmoke-400">${this.#esc(right.label)}</span><span class="text-sm text-crusta-400 font-medium">${this.#esc(right.value)}</span></div>`;
      } else {
        row += '<div class="px-5 py-3"></div>';
      }
      row += "</div>";
      gridRows.push(row);
    }

    this.displayTarget.innerHTML = gridRows.join(
      '<div class="border-t border-woodsmoke-800"></div>'
    );
  }
}
