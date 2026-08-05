class ElementsController < ApplicationController
  def index
    @elements = Element.order(:atomic_number)
    @elements_by_position = @elements.where.not(atomic_number: 58..71).where.not(atomic_number: 90..103).index_by { |element| [element.period, element.group_number] }
    @lanthanides = @elements.where(atomic_number: 57..71)
    @actinides = @elements.where(atomic_number: 89..103)
  end

  def show
    @element = Element.find(params[:id])
  end
end
