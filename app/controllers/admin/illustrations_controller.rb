module Admin
  # 管理用イラスト一覧: 公開・非公開を含む全投稿を確認する。
  class IllustrationsController < BaseController
    def index
      @illustrations = Illustration.includes(:user, :element).with_attached_image.order(created_at: :desc)
    end
  end
end
