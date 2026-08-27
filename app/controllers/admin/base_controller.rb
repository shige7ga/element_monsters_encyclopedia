module Admin
  # 管理画面共通の認証・認可を集約する基底コントローラー。
  class BaseController < ApplicationController
    before_action :authorize_admin!

    private

    def authorize_admin!
      return if current_user&.admin?

      if current_user
        redirect_to root_path, alert: t("flash.admin.unauthorized")
      else
        redirect_to root_path
      end
    end
  end
end
