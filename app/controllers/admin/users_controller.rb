module Admin
  # 管理用ユーザー一覧: 読み取り専用で登録状況を確認する。
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc)
    end
  end
end
