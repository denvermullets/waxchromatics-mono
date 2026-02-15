import { Controller } from "@hotwired/stimulus";

// Debounces a search input and loads results into a turbo-frame by setting its src.
// No <form> needed — avoids nested form issues.
//
// Usage:
//   <input data-controller="debounce-submit"
//          data-debounce-submit-url-value="/trades/search_collection"
//          data-debounce-submit-frame-value="send_results"
//          data-debounce-submit-extra-params-value='{"recipient_id":"2"}'
//          data-action="input->debounce-submit#search">
export default class extends Controller {
  static values = {
    url: String,
    frame: String,
    extraParams: { type: Object, default: {} },
    delay: { type: Number, default: 300 },
    minLength: { type: Number, default: 2 },
  };

  connect() {
    this.timeout = null;
    this.handleClickOutside = this.clickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  clickOutside(event) {
    const frame = document.getElementById(this.frameValue);
    if (
      !this.element.contains(event.target) &&
      (!frame || !frame.contains(event.target))
    ) {
      if (frame) frame.innerHTML = "";
    }
  }

  search() {
    clearTimeout(this.timeout);
    const query = this.element.value.trim();

    if (query.length < this.minLengthValue) {
      // Clear the frame when query is too short
      const frame = document.getElementById(this.frameValue);
      if (frame) frame.innerHTML = "";
      return;
    }

    this.timeout = setTimeout(() => this.load(query), this.delayValue);
  }

  load(query) {
    const params = new URLSearchParams({ q: query, ...this.extraParamsValue });
    const frame = document.getElementById(this.frameValue);
    if (frame) frame.src = `${this.urlValue}?${params}`;
  }

  disconnect() {
    clearTimeout(this.timeout);
    document.removeEventListener("click", this.handleClickOutside);
  }
}
