import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const date = new Date(this.element.dateTime)
    if (!Number.isNaN(date.getTime())) {
      this.element.textContent = date.toLocaleString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })
    }
  }
}
