import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "csrfToken"]

  open(event) {
    this.formTarget.action = event.params.url
    this.csrfTokenTarget.value = event.params.csrfToken
    this.dialogTarget.showModal()
  }

  close(event) {
    event.currentTarget.closest("dialog")?.close()
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }
}
