module Admin
  # 管理画面共通の認証・認可を集約する基底コントローラー。
  class BaseController < ApplicationController
    before_action :authorize_admin!

    private

    def authorize_admin!
      return if current_user&.admin?

      redirect_to root_path, alert: "管理画面へのアクセス権限がありません。"
    end
  end
end
