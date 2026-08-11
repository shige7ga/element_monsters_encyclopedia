module Admin
  # 管理画面トップ: 運用状況を最小限の件数で確認する。
  class DashboardController < BaseController
    def show
      @users_count = User.count
      @illustrations_count = Illustration.count
    end
  end
end
