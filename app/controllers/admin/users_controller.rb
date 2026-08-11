module Admin
  # 管理用ユーザー一覧: 登録状況の確認と削除を行う。
  class UsersController < BaseController
    before_action :set_user, only: %i[show destroy]

    def index
      @users = User.order(created_at: :desc)
    end

    def show
      @illustrations = @user.illustrations.includes(:element).with_attached_image.order(created_at: :desc)
    end

    def destroy
      @user.destroy!

      redirect_to admin_users_path, notice: "ユーザーを削除しました。"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
