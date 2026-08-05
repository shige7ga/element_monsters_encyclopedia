import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "symbol", "name", "detailLink"]

  open(event) {
    this.close()

    const button = event.currentTarget
    const { elementName, elementSymbol, elementUrl } = button.dataset
    const rect = button.getBoundingClientRect()

    this.symbolTarget.textContent = elementSymbol
    this.nameTarget.textContent = elementName
    this.detailLinkTarget.href = elementUrl
    this.popupTarget.style.left = `${Math.min(rect.left, window.innerWidth - 240)}px`
    this.popupTarget.style.top = `${Math.min(rect.bottom + 10, window.innerHeight - 170)}px`
    this.popupTarget.classList.remove("hidden")
    button.classList.add("scale-125", "z-20", "shadow-lg")
    this.activeButton = button
  }

  close() {
    this.popupTarget.classList.add("hidden")
    this.activeButton?.classList.remove("scale-125", "z-20", "shadow-lg")
    this.activeButton = null
  }
}
