class IllustrationsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show popular]
  before_action :set_illustration, only: :show
  before_action :set_owned_illustration, only: %i[edit update destroy]
  before_action :authorize_view!, only: :show

  def index
    @gallery_title = "イラスト集"
    @gallery_description = "元素モンスターを見て、あなたの推し元素を探そう"
    @illustrations = visible_illustrations.order(created_at: :desc).page(params[:page]).per(12)
  end

  def popular
    @illustrations = Illustration.published.popular.includes(:user, :element, :likes).with_attached_image.page(params[:page]).per(12)
    render :index
  end

  def liked
    @gallery_title = "いいねしたイラスト"
    @gallery_description = "あなたがいいねした元素モンスターの一覧です"
    @illustrations = current_user.liked_illustrations.visible_to(current_user).includes(:user, :element, :likes).with_attached_image.order(created_at: :desc).page(params[:page]).per(12)
    render :index
  end

  def show
    @encyclopedia_entry = current_user&.encyclopedia_entries&.find_by(element_id: @illustration.element_id)
  end

  def new
    @illustration = current_user.illustrations.build(
      element_id: selected_element_id,
      creation_type: ai_generated_from_assist? ? "ai_generated" : nil
    )
  end

  def create
    @illustration = current_user.illustrations.build(illustration_params)

    if @illustration.save
      redirect_to @illustration, notice: "イラストを投稿しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @illustration.update(illustration_params)
      redirect_to @illustration, notice: "イラストを更新しました。"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    # 作品レコードより先にActive Storage経由で保存先の画像を削除する
    @illustration.image.purge if @illustration.image.attached?
    @illustration.destroy!

    redirect_to illustrations_path, notice: "イラストを削除しました。"
  end

  private

  def set_illustration
    @illustration = Illustration.includes(:likes).find(params[:id])
  end

  def set_owned_illustration
    @illustration = current_user.illustrations.find(params[:id])
  end

  def authorize_view!
    return if @illustration.viewable_by?(current_user)

    redirect_to illustrations_path, alert: "このイラストは非公開です。"
  end

  # 一覧カードでいいね数といいね状態を表示するためにLikeを事前読み込みする
  def visible_illustrations
    Illustration.visible_to(current_user).includes(:user, :element, :likes).with_attached_image
  end

  # 投稿画面への導線から渡された元素だけを初期選択する
  def selected_element_id
    Element.find_by(id: params[:element_id])&.id
  end

  # アシストで画像生成した利用者だけ、投稿時の作成方法をAI生成で初期選択する。
  def ai_generated_from_assist?
    params[:from_ai_assist] == "1"
  end

  def illustration_params
    params.require(:illustration).permit(:element_id, :image, :monster_name, :description, :creation_type, :published)
  end
end
