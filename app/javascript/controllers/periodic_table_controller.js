import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup"]

  toggle(event) {
    const cell = event.currentTarget.closest("[data-periodic-table-cell]")
    const popup = cell.querySelector("[data-periodic-table-target='popup']")
    const isOpening = popup.classList.contains("hidden")

    this.popupTargets.forEach((target) => target.classList.add("hidden"))
    if (isOpening) popup.classList.remove("hidden")
  }
}
