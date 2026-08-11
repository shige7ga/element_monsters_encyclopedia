import { Controller } from "@hotwired/stimulus"

// 成功通知だけを表示後に閉じ、エラー通知はユーザーが確認できるよう残す。
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.close(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    this.element.remove()
  }
}
