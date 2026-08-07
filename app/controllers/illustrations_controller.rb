class IllustrationsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_illustration, only: :show
  before_action :set_owned_illustration, only: %i[edit update destroy]
  before_action :authorize_view!, only: :show

  def index
    @illustrations = Illustration.visible_to(current_user).includes(:user, :element).with_attached_image.order(created_at: :desc)
  end

  def show
  end

  def new
    @illustration = current_user.illustrations.build(element_id: selected_element_id)
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
    @illustration = Illustration.find(params[:id])
  end

  def set_owned_illustration
    @illustration = current_user.illustrations.find(params[:id])
  end

  def authorize_view!
    return if @illustration.viewable_by?(current_user)

    redirect_to illustrations_path, alert: "このイラストは非公開です。"
  end

  # 投稿画面への導線から渡された元素だけを初期選択する
  def selected_element_id
    Element.find_by(id: params[:element_id])&.id
  end

  def illustration_params
    params.require(:illustration).permit(:element_id, :image, :monster_name, :description, :published)
  end
end
