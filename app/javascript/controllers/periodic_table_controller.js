import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "symbol", "name", "detailLink"]

  open(event) {
    const { elementName, elementSymbol, elementUrl } = event.currentTarget.dataset

    this.symbolTarget.textContent = elementSymbol
    this.nameTarget.textContent = elementName
    this.detailLinkTarget.href = elementUrl
    this.popupTarget.classList.remove("hidden")
  }

  close() {
    this.popupTarget.classList.add("hidden")
  }
}
