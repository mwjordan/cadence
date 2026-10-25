import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 15000 } }

  connect() {
    this.timer = setInterval(() => {
      const editing = ["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName)
      if (document.visibilityState === "visible" && !editing) {
        if (this.element.hasAttribute("src")) this.element.reload()
        else this.element.src = window.location.href
      }
    }, this.intervalValue)
  }

  disconnect() { clearInterval(this.timer) }
}
