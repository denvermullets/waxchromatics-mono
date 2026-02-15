import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results", "container", "hiddenFields"];
  static values = { url: String, existing: { type: Array, default: [] } };

  connect() {
    this.timeout = null;
    this.selected = new Map();
    this.loadExisting();
  }

  loadExisting() {
    this.existingValue.forEach((rg) => {
      const id = String(rg.id);
      const title = rg.title || "";
      const year = rg.year ? String(rg.year) : "";
      const cover = rg.cover_art_url || "";

      this.selected.set(id, { title, year, cover });

      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "artist[release_group_ids][]";
      input.value = id;
      input.dataset.rgId = id;
      this.hiddenFieldsTarget.appendChild(input);

      this.containerTarget.insertAdjacentHTML("beforeend", this.buildCard(id, title, year, cover));
    });
  }

  search() {
    clearTimeout(this.timeout);
    const query = this.inputTarget.value.trim();

    if (query.length < 2) {
      this.resultsTarget.innerHTML = "";
      this.resultsTarget.classList.add("hidden");
      return;
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 300);
  }

  async fetchResults(query) {
    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`;
    const response = await fetch(url);
    const groups = await response.json();

    const available = groups.filter((g) => !this.selected.has(String(g.id)));

    if (available.length === 0) {
      this.resultsTarget.innerHTML =
        '<div class="px-3 py-2 text-woodsmoke-400 text-sm">No release groups found</div>';
      this.resultsTarget.classList.remove("hidden");
      return;
    }

    this.resultsTarget.innerHTML = available
      .map(
        (g) =>
          `<button type="button"
                   class="block w-full text-left px-3 py-2 text-woodsmoke-100 hover:bg-woodsmoke-800 text-sm"
                   data-action="click->release-group-search#select"
                   data-rg-id="${g.id}"
                   data-rg-title="${this.escapeHtml(g.title)}"
                   data-rg-year="${g.year || ""}"
                   data-rg-cover="${this.escapeHtml(g.cover_art_url || "")}">
            <span>${this.escapeHtml(g.title)}</span>
            ${g.year ? `<span class="text-woodsmoke-500 ml-2">(${g.year})</span>` : ""}
          </button>`
      )
      .join("");
    this.resultsTarget.classList.remove("hidden");
  }

  select(event) {
    event.preventDefault();
    const button = event.target.closest("[data-rg-id]");
    if (!button) return;

    const { rgId, rgTitle, rgYear, rgCover } = button.dataset;
    if (this.selected.has(rgId)) return;

    this.selected.set(rgId, { title: rgTitle, year: rgYear, cover: rgCover });

    // Add hidden field
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = "artist[release_group_ids][]";
    input.value = rgId;
    input.dataset.rgId = rgId;
    this.hiddenFieldsTarget.appendChild(input);

    // Add card to container
    this.containerTarget.insertAdjacentHTML(
      "beforeend",
      this.buildCard(rgId, rgTitle, rgYear, rgCover)
    );

    // Clear search
    this.inputTarget.value = "";
    this.resultsTarget.innerHTML = "";
    this.resultsTarget.classList.add("hidden");
  }

  remove(event) {
    event.preventDefault();
    const card = event.target.closest("[data-rg-card]");
    if (!card) return;

    const rgId = card.dataset.rgCard;
    this.selected.delete(rgId);

    // Remove hidden field
    const input = this.hiddenFieldsTarget.querySelector(`input[data-rg-id="${rgId}"]`);
    if (input) input.remove();

    card.remove();
  }

  buildCard(id, title, year, cover) {
    const coverHtml = cover
      ? `<img src="${this.escapeHtml(cover)}" alt="${this.escapeHtml(title)}" class="w-full h-full object-cover">`
      : `<svg class="w-10 h-10 text-woodsmoke-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19V6l12-3v13M9 19c0 1.1-1.3 2-3 2s-3-.9-3-2 1.3-2 3-2 3 .9 3 2zm12-3c0 1.1-1.3 2-3 2s-3-.9-3-2 1.3-2 3-2 3 .9 3 2z"/>
         </svg>`;

    return `<div data-rg-card="${id}" class="p-4 rounded-sm border border-woodsmoke-700 bg-woodsmoke-925 flex items-start gap-4">
      <div class="shrink-0 w-20 h-20 rounded bg-woodsmoke-925 flex items-center justify-center overflow-hidden">
        ${coverHtml}
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-start justify-between gap-2">
          <p class="font-semibold text-woodsmoke-50 truncate">${this.escapeHtml(title)}</p>
          ${year ? `<span class="shrink-0 text-xs text-woodsmoke-400">${this.escapeHtml(year)}</span>` : ""}
        </div>
      </div>
      <button type="button"
              class="shrink-0 text-woodsmoke-500 hover:text-crusta-400 transition-colors"
              data-action="click->release-group-search#remove">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    </div>`;
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
