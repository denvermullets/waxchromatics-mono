import { Controller } from "@hotwired/stimulus";

// Debounces form submission. Attach to a form or a wrapper containing a form.
// Use data-action="input->debounce-submit#submit" on the input.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } };

  connect() {
    this.timeout = null;
  }

  submit() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      const form = this.element.closest("form") || this.element.querySelector("form");
      if (form) form.requestSubmit();
    }, this.delayValue);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
