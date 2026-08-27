module Users
  # ユーザー情報更新後の遷移先と完了メッセージだけをDevise標準から調整する。
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_update_path_for(_resource)
      flash[:notice] = t("flash.users.profile_updated")
      mypage_path
    end
  end
end
