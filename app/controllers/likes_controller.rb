class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_illustration

  def create
    current_user.likes.create_or_find_by!(illustration: @illustration)
    respond_with_like_button(t("flash.likes.created"))
  end

  def destroy
    current_user.likes.find_by!(illustration: @illustration).destroy!
    respond_with_like_button(t("flash.likes.destroyed"))
  end

  private

  # 非公開作品は投稿者本人以外がいいねできないよう、既存の閲覧範囲を利用する
  def set_illustration
    @illustration = Illustration.visible_to(current_user).includes(:likes).find(params[:illustration_id])
  end

  # Turbo操作時は、押下したいいねボタンだけを最新の状態へ置き換える。
  def respond_with_like_button(notice)
    # create/destroy前の関連キャッシュを破棄し、最新の件数・状態を描画する。
    @illustration.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@illustration, :like_button),
          partial: "likes/button",
          locals: { illustration: @illustration, alignment: params[:alignment] || "justify-end" }
        )
      end
      format.html { redirect_back fallback_location: illustration_path(@illustration), notice: notice }
    end
  end
end
