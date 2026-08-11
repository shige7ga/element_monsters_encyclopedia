module DeleteConfirmationHelper
  # 全削除ボタンに共通の確認ダイアログを開くトリガーを生成する。
  def delete_confirmation_button(label, path, class_name:)
    csrf_token = form_authenticity_token(form_options: { action: path, method: :delete })

    button_tag label,
               type: "button",
               class: class_name,
               data: {
                 action: "delete-confirmation#open",
                 delete_confirmation_url_param: path,
                 delete_confirmation_csrf_token_param: csrf_token
               }
  end
end
