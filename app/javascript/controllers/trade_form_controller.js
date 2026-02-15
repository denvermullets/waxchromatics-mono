import { Controller } from "@hotwired/stimulus";

// Handles client-side-only operations for the trade form.
// Search and item addition are handled by Turbo Frames/Streams.
export default class extends Controller {
  // Remove a selected item (card + hidden field) — no server round-trip needed
  removeItem(event) {
    event.preventDefault();
    const button = event.target.closest("[data-item-id]");
    if (!button) return;

    const { itemId, side } = button.dataset;
    const card = document.getElementById(`${side}_item_${itemId}`);
    const hidden = document.getElementById(`${side}_hidden_${itemId}`);

    if (card) card.remove();
    if (hidden) hidden.remove();
  }

  // Clear the selected recipient and reset receive side
  clearRecipient() {
    const area = document.getElementById("recipient_area");
    if (area) {
      area.innerHTML = `
        <input type="hidden" name="trade[recipient_id]" value="">
        <input type="text" placeholder="Search users..." autocomplete="off"
               data-controller="debounce-submit"
               data-debounce-submit-url-value="${this.searchUsersUrl}"
               data-debounce-submit-frame-value="recipient_results"
               data-action="input->debounce-submit#search"
               class="w-full bg-woodsmoke-900 border border-woodsmoke-800 rounded-sm px-3 py-2 text-sm text-woodsmoke-100 placeholder-woodsmoke-500 focus:border-crusta-400 focus:outline-none">
        <turbo-frame id="recipient_results" class="absolute left-0 top-full z-10 w-full mt-1 max-h-48 overflow-y-auto"></turbo-frame>
      `;
    }

    // Clear receive items and disable receive search
    const receiveItems = document.getElementById("receive_items");
    const receiveHidden = document.getElementById("receive_hidden_fields");
    const receiveForm = document.getElementById("receive_search_form");

    if (receiveItems) receiveItems.innerHTML = "";
    if (receiveHidden) receiveHidden.innerHTML = "";
    if (receiveForm) {
      receiveForm.innerHTML = `
        <input type="text" placeholder="Select a trade partner first..." disabled autocomplete="off"
               class="w-full bg-woodsmoke-900 border border-woodsmoke-800 rounded-sm px-3 py-2 text-sm text-woodsmoke-500 cursor-not-allowed">
        <turbo-frame id="receive_results" class="absolute left-0 top-full z-10 w-full mt-1 max-h-48 overflow-y-auto"></turbo-frame>
      `;
    }
  }

  get searchUsersUrl() {
    return (
      this.element.dataset.tradeFormSearchUsersUrlValue ||
      "/trades/search_users"
    );
  }
}
