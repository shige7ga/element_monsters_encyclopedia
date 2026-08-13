import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "name"]

  update() {
    this.nameTarget.textContent = this.inputTarget.files[0]?.name || "画像を選択してください"
  }
}
