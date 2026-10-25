import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }
  static targets = ["status"]

  speak() {
    if (!("speechSynthesis" in window)) {
      this.statusTarget.textContent = "This browser does not support speech preview."
      return
    }
    window.speechSynthesis.cancel()
    const utterance = new SpeechSynthesisUtterance(this.messageValue)
    utterance.onend = () => { this.statusTarget.textContent = "Preview finished. Use the buttons to save your answer." }
    utterance.onerror = () => { this.statusTarget.textContent = "Speech preview could not play on this device." }
    this.statusTarget.textContent = "Playing spoken prompt…"
    window.speechSynthesis.speak(utterance)
  }
}
