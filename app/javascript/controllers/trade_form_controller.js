import { Controller } from "@hotwired/stimulus";

// Handles the new trade form's recipient selection.
// Item add/remove is handled entirely by Turbo Streams.
export default class extends Controller {
  // Clear the selected recipient and reset receive side
  clearRecipient() {
    // Clear the hidden recipient_id in the form
    const recipientHidden = document.getElementById("recipient_hidden");
    if (recipientHidden) {
      recipientHidden.innerHTML = `<input type="hidden" name="trade[recipient_id]" value="">`;
    }

    // Reset the visible recipient area to show search input
    const area = document.getElementById("recipient_area");
    if (area) {
      area.innerHTML = `
        <input type="text" placeholder="Search users..." autocomplete="off"
               data-controller="debounce-submit"
               data-debounce-submit-url-value="${this.searchUsersUrl}"
               data-debounce-submit-frame-value="recipient_results"
               data-action="input->debounce-submit#search"
               class="w-full bg-woodsmoke-925 border border-woodsmoke-800 rounded-sm px-3 py-2 text-sm text-woodsmoke-100 placeholder-woodsmoke-500 focus:border-crusta-400 focus:outline-none">
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
