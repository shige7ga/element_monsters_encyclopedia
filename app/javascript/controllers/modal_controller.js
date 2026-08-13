import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    this.openDialog(event.params.dialog)
  }

  switch(event) {
    event.preventDefault()
    this.openDialog(event.params.dialog)
  }

  openDialog(dialogName) {
    const dialog = this.dialogTargets.find((target) => target.dataset.modalDialog === dialogName)
    const frame = dialog?.querySelector("turbo-frame")

    this.dialogTargets.filter((target) => target.open).forEach((target) => target.close())
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
