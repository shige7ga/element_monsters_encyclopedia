import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle() {
    const isOpen = this.menuTarget.classList.toggle("hidden") === false

    this.buttonTarget.setAttribute("aria-expanded", isOpen)
    this.buttonTarget.setAttribute("aria-label", isOpen ? "メニューを閉じる" : "メニューを開く")
  }
}
