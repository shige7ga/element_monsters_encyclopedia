class ElementsController < ApplicationController
  def index
    @elements = Element.order(:atomic_number)
    @elements_by_position = @elements.where.not(atomic_number: 58..71).where.not(atomic_number: 90..103).index_by { |element| [ element.period, element.group_number ] }
    @lanthanides = @elements.where(atomic_number: 57..71)
    @actinides = @elements.where(atomic_number: 89..103)
  end

  def show
    @element = Element.find(params[:id])
    @illustration_sort = %w[newest popular].include?(params[:sort]) ? params[:sort] : "recommended"
    @illustrations = element_illustrations
  end

  private

  # おすすめは公開作品のみ、既存のおすすめスコープを使ってランダムに表示する。
  # 新着・人気では公開作品と閲覧中ユーザー自身の非公開作品を表示する。
  def element_illustrations
    illustrations = @element.illustrations.visible_to(current_user).includes(:user, :likes).with_attached_image

    sorted_illustrations = case @illustration_sort
    when "recommended"
      illustrations.published.recommended
    when "popular"
      illustrations.popular
    else
      illustrations.order(created_at: :desc)
    end

    sorted_illustrations.page(params[:page]).per(12)
  end
end
