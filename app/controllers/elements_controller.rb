class ElementsController < ApplicationController
  def index
    @elements = Element.order(:atomic_number)
    @elements_by_position = @elements.where.not(atomic_number: 58..71).where.not(atomic_number: 90..103).index_by { |element| [ element.period, element.group_number ] }
    @lanthanides = @elements.where(atomic_number: 57..71)
    @actinides = @elements.where(atomic_number: 89..103)
  end

  def show
    @element = Element.find(params[:id])
    @illustration_sort = params[:sort] == "popular" ? "popular" : "newest"
    @illustrations = element_illustrations
  end

  private

  # 元素詳細では公開作品と閲覧中ユーザー自身の非公開作品だけを並び替える。
  def element_illustrations
    illustrations = @element.illustrations.visible_to(current_user).includes(:user, :likes).with_attached_image

    (@illustration_sort == "popular" ? illustrations.popular : illustrations.order(created_at: :desc)).page(params[:page]).per(10)
  end
end
