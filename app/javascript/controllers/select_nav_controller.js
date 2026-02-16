import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    const param = event.target.dataset.selectNavParamValue
    const value = event.target.value
    const url = new URL(window.location)
    if (value) {
      url.searchParams.set(param, value)
    } else {
      url.searchParams.delete(param)
    }
    url.searchParams.delete("page")
    window.location = url.toString()
  }
}
