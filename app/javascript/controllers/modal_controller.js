import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    const dialog = this.dialogTargets.find((target) => target.dataset.modalDialog === event.params.dialog)
    const frame = dialog?.querySelector("turbo-frame")

    if (frame && !frame.src) frame.src = dialog.dataset.modalSource

    dialog?.showModal()
  }

  close(event) {
    event.currentTarget.closest("dialog")?.close()
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }
}
