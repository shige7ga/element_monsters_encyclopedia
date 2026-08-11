module Admin
  # 管理用イラスト一覧: 全投稿の確認、削除、公開状態の切替を行う。
  class IllustrationsController < BaseController
    before_action :set_illustration, only: %i[show destroy toggle_published]

    def index
      @illustrations = Illustration.includes(:user, :element).with_attached_image.order(created_at: :desc)
    end

    def show
    end

    def destroy
      @illustration.image.purge if @illustration.image.attached?
      @illustration.destroy!

      redirect_to admin_illustrations_path, notice: "イラストを削除しました。"
    end

    def toggle_published
      @illustration.update!(published: !@illustration.published?)

      redirect_to admin_illustration_path(@illustration), notice: "公開状態を変更しました。"
    end

    private

    def set_illustration
      @illustration = Illustration.includes(:user, :element).with_attached_image.find(params[:id])
    end
  end
end
