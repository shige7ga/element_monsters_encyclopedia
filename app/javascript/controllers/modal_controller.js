import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    const dialog = this.dialogTargets.find((target) => target.dataset.modalDialog === event.params.dialog)
    dialog?.showModal()
  }

  close(event) {
    event.currentTarget.closest("dialog")?.close()
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }
}
