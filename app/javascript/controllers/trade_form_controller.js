import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "recipientId",
    "recipientDisplay",
    "recipientSearch",
    "recipientInput",
    "recipientResults",
    "sendSearch",
    "sendResults",
    "sendItems",
    "sendHiddenFields",
    "receiveSearch",
    "receiveResults",
    "receiveItems",
    "receiveHiddenFields",
  ];

  static values = {
    searchUsersUrl: String,
    searchCollectionUrl: String,
    searchRecipientCollectionUrl: String,
    preSend: { type: Array, default: [] },
    preReceive: { type: Array, default: [] },
    recipientId: { type: String, default: "" },
    recipientUsername: { type: String, default: "" },
  };

  connect() {
    this.userTimeout = null;
    this.sendTimeout = null;
    this.receiveTimeout = null;
    this.sendSelected = new Map();
    this.receiveSelected = new Map();

    this.loadPrePopulated();
  }

  loadPrePopulated() {
    // Items are already resolved collection items from the controller
    for (const item of this.preSendValue) {
      if (item.id) this.addItem("send", item);
    }
    for (const item of this.preReceiveValue) {
      if (item.id) this.addItem("receive", item);
    }
  }

  // --- Recipient search ---
  searchUsers() {
    clearTimeout(this.userTimeout);
    const input = this.recipientInputTarget.querySelector("input");
    const query = input.value.trim();

    if (query.length < 2) {
      this.recipientResultsTarget.innerHTML = "";
      this.recipientResultsTarget.classList.add("hidden");
      return;
    }

    this.userTimeout = setTimeout(() => this.fetchUsers(query), 300);
  }

  async fetchUsers(query) {
    const url = `${this.searchUsersUrlValue}?q=${encodeURIComponent(query)}`;
    const response = await fetch(url);
    const users = await response.json();

    if (users.length === 0) {
      this.recipientResultsTarget.innerHTML =
        '<div class="px-3 py-2 text-woodsmoke-400 text-sm">No users found</div>';
      this.recipientResultsTarget.classList.remove("hidden");
      return;
    }

    this.recipientResultsTarget.innerHTML = users
      .map(
        (u) =>
          `<button type="button"
                   class="block w-full text-left px-3 py-2 text-woodsmoke-100 hover:bg-woodsmoke-800 text-sm"
                   data-action="click->trade-form#selectRecipient"
                   data-user-id="${u.id}"
                   data-user-name="${this.escapeHtml(u.username)}">
            ${this.escapeHtml(u.username)}
          </button>`
      )
      .join("");
    this.recipientResultsTarget.classList.remove("hidden");
  }

  selectRecipient(event) {
    event.preventDefault();
    const button = event.target.closest("[data-user-id]");
    if (!button) return;

    const { userId, userName } = button.dataset;
    this.recipientIdTarget.value = userId;
    this.recipientSearchTarget.textContent = userName;
    this.recipientDisplayTarget.classList.remove("hidden");
    this.recipientInputTarget.classList.add("hidden");
    this.recipientResultsTarget.classList.add("hidden");

    // Clear receive items when recipient changes
    this.receiveSelected.clear();
    this.receiveItemsTarget.innerHTML = "";
    this.receiveHiddenFieldsTarget.innerHTML = "";
  }

  clearRecipient(event) {
    event.preventDefault();
    this.recipientIdTarget.value = "";
    this.recipientSearchTarget.textContent = "";
    this.recipientDisplayTarget.classList.add("hidden");
    this.recipientInputTarget.classList.remove("hidden");
    this.recipientInputTarget.querySelector("input").value = "";

    // Clear receive items
    this.receiveSelected.clear();
    this.receiveItemsTarget.innerHTML = "";
    this.receiveHiddenFieldsTarget.innerHTML = "";
  }

  // --- Send (your collection) search ---
  searchSend() {
    clearTimeout(this.sendTimeout);
    const query = this.sendSearchTarget.value.trim();

    if (query.length < 2) {
      this.sendResultsTarget.innerHTML = "";
      this.sendResultsTarget.classList.add("hidden");
      return;
    }

    this.sendTimeout = setTimeout(() => this.fetchCollection("send", query), 300);
  }

  // --- Receive (recipient collection) search ---
  searchReceive() {
    clearTimeout(this.receiveTimeout);
    const query = this.receiveSearchTarget.value.trim();
    const recipientId = this.recipientIdTarget.value;

    if (!recipientId) {
      this.receiveResultsTarget.innerHTML =
        '<div class="px-3 py-2 text-woodsmoke-400 text-sm">Select a trade partner first</div>';
      this.receiveResultsTarget.classList.remove("hidden");
      return;
    }

    if (query.length < 2) {
      this.receiveResultsTarget.innerHTML = "";
      this.receiveResultsTarget.classList.add("hidden");
      return;
    }

    this.receiveTimeout = setTimeout(
      () => this.fetchCollection("receive", query),
      300
    );
  }

  async fetchCollection(side, query) {
    const selected = side === "send" ? this.sendSelected : this.receiveSelected;
    const resultsTarget =
      side === "send" ? this.sendResultsTarget : this.receiveResultsTarget;

    let url;
    if (side === "send") {
      url = `${this.searchCollectionUrlValue}?q=${encodeURIComponent(query)}`;
    } else {
      const recipientId = this.recipientIdTarget.value;
      url = `${this.searchRecipientCollectionUrlValue}?q=${encodeURIComponent(query)}&recipient_id=${recipientId}`;
    }

    const response = await fetch(url);
    const items = await response.json();
    const available = items.filter((i) => !selected.has(String(i.id)));

    if (available.length === 0) {
      resultsTarget.innerHTML =
        '<div class="px-3 py-2 text-woodsmoke-400 text-sm">No items found</div>';
      resultsTarget.classList.remove("hidden");
      return;
    }

    resultsTarget.innerHTML = available
      .map(
        (item) =>
          `<button type="button"
                   class="block w-full text-left px-3 py-2 text-woodsmoke-100 hover:bg-woodsmoke-800 text-sm"
                   data-action="click->trade-form#selectItem"
                   data-side="${side}"
                   data-item-id="${item.id}"
                   data-item-release-id="${item.release_id}"
                   data-item-title="${this.escapeHtml(item.title)}"
                   data-item-artist="${this.escapeHtml(item.artist || "")}"
                   data-item-cover="${this.escapeHtml(item.cover_art_url || "")}"
                   data-item-condition="${this.escapeHtml(item.condition || "")}">
            <span>${this.escapeHtml(item.title)}</span>
            ${item.artist ? `<span class="text-woodsmoke-500 ml-2">- ${this.escapeHtml(item.artist)}</span>` : ""}
            ${item.condition ? `<span class="text-woodsmoke-500 ml-2">(${this.escapeHtml(item.condition)})</span>` : ""}
          </button>`
      )
      .join("");
    resultsTarget.classList.remove("hidden");
  }

  selectItem(event) {
    event.preventDefault();
    const button = event.target.closest("[data-item-id]");
    if (!button) return;

    const { side, itemId, itemTitle, itemArtist, itemCover, itemCondition } =
      button.dataset;

    this.addItem(side, {
      id: parseInt(itemId),
      title: itemTitle,
      artist: itemArtist,
      cover_art_url: itemCover,
      condition: itemCondition,
    });

    // Clear search
    const searchTarget =
      side === "send" ? this.sendSearchTarget : this.receiveSearchTarget;
    const resultsTarget =
      side === "send" ? this.sendResultsTarget : this.receiveResultsTarget;
    searchTarget.value = "";
    resultsTarget.innerHTML = "";
    resultsTarget.classList.add("hidden");
  }

  addItem(side, item) {
    const selected = side === "send" ? this.sendSelected : this.receiveSelected;
    const itemsTarget =
      side === "send" ? this.sendItemsTarget : this.receiveItemsTarget;
    const hiddenTarget =
      side === "send"
        ? this.sendHiddenFieldsTarget
        : this.receiveHiddenFieldsTarget;
    const paramName = side === "send" ? "send_items[]" : "receive_items[]";

    const id = String(item.id);
    if (selected.has(id)) return;

    selected.set(id, item);

    // Add hidden field
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = paramName;
    input.value = id;
    input.dataset.itemId = id;
    hiddenTarget.appendChild(input);

    // Add card
    itemsTarget.insertAdjacentHTML("beforeend", this.buildItemCard(side, item));
  }

  removeItem(event) {
    event.preventDefault();
    const card = event.target.closest("[data-item-card]");
    if (!card) return;

    const { itemCard: itemId, side } = card.dataset;
    const selected = side === "send" ? this.sendSelected : this.receiveSelected;
    const hiddenTarget =
      side === "send"
        ? this.sendHiddenFieldsTarget
        : this.receiveHiddenFieldsTarget;

    selected.delete(itemId);
    const input = hiddenTarget.querySelector(`input[data-item-id="${itemId}"]`);
    if (input) input.remove();
    card.remove();
  }

  buildItemCard(side, item) {
    const coverHtml = item.cover_art_url
      ? `<img src="${this.escapeHtml(item.cover_art_url)}" alt="${this.escapeHtml(item.title)}" class="w-full h-full object-cover">`
      : `<svg class="w-8 h-8 text-woodsmoke-500" fill="currentColor" viewBox="0 0 24 24">
           <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.5c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-5.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z"/>
         </svg>`;

    const conditionHtml = item.condition
      ? `<span class="shrink-0 px-1.5 py-0.5 text-[10px] bg-woodsmoke-800 text-woodsmoke-300 rounded">${this.escapeHtml(item.condition)}</span>`
      : "";

    return `<div data-item-card="${item.id}" data-side="${side}" class="flex items-center gap-2 bg-woodsmoke-900 rounded-sm p-2">
      <div class="shrink-0 w-10 h-10 rounded bg-woodsmoke-925 flex items-center justify-center overflow-hidden">
        ${coverHtml}
      </div>
      <div class="min-w-0 flex-1">
        <p class="text-xs text-woodsmoke-200 truncate">${this.escapeHtml(item.title)}</p>
        ${item.artist ? `<p class="text-[10px] text-woodsmoke-400 truncate">${this.escapeHtml(item.artist)}</p>` : ""}
      </div>
      ${conditionHtml}
      <button type="button"
              class="shrink-0 text-woodsmoke-500 hover:text-crusta-400 transition-colors"
              data-action="click->trade-form#removeItem">
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
