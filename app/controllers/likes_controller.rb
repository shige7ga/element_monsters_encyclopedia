class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_illustration

  def create
    current_user.likes.create_or_find_by!(illustration: @illustration)
    redirect_back fallback_location: illustration_path(@illustration), notice: "いいねしました。"
  end

  def destroy
    current_user.likes.find_by!(illustration: @illustration).destroy!
    redirect_back fallback_location: illustration_path(@illustration), notice: "いいねを解除しました。"
  end

  private

  # 非公開作品は投稿者本人以外がいいねできないよう、既存の閲覧範囲を利用する
  def set_illustration
    @illustration = Illustration.visible_to(current_user).find(params[:illustration_id])
  end
end
