import { Controller } from "@hotwired/stimulus"

// 生成したプロンプトをクリップボードへコピーし、結果をその場で知らせる。
export default class extends Controller {
  static targets = ["source", "feedback"]

  async copy() {
    const text = this.sourceTarget.value

    try {
      await navigator.clipboard.writeText(text)
    } catch (_error) {
      this.sourceTarget.select()
      document.execCommand("copy")
    }

    this.feedbackTarget.hidden = false
  }
}
