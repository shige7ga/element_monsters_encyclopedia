class IllustrationsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show popular]
  before_action :set_illustration, only: :show
  before_action :set_owned_illustration, only: %i[edit update destroy]
  before_action :authorize_view!, only: :show

  def index
    @gallery_title = t("views.illustrations.index.title")
    @gallery_description = t("views.illustrations.index.description")
    @illustration_sort = params[:sort] == "newest" ? "newest" : "recommended"
    @illustrations = index_illustrations.page(params[:page]).per(12)
  end

  def popular
    @illustration_sort = "popular"
    @illustrations = published_illustrations.popular.page(params[:page]).per(12)
    render :index
  end

  def liked
    @gallery_title = t("views.illustrations.liked.title")
    @gallery_description = t("views.illustrations.liked.description")
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
      redirect_to @illustration, notice: t("flash.illustrations.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @illustration.update(illustration_params)
      redirect_to @illustration, notice: t("flash.illustrations.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    # 作品レコードより先にActive Storage経由で保存先の画像を削除する
    @illustration.image.purge if @illustration.image.attached?
    @illustration.destroy!

    redirect_to illustrations_path, notice: t("flash.illustrations.destroyed")
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

    redirect_to illustrations_path, alert: t("flash.illustrations.private")
  end

  # 一覧カードでいいね数といいね状態を表示するためにLikeを事前読み込みする
  # おすすめは公開作品をランダム表示し、新着は従来どおり本人の非公開作品も含める
  def index_illustrations
    return visible_illustrations.order(created_at: :desc) if @illustration_sort == "newest"

    published_illustrations.recommended
  end

  # おすすめ・人気一覧では公開済み作品だけを表示する
  def published_illustrations
    Illustration.published.includes(:user, :element, :likes).with_attached_image
  end

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
