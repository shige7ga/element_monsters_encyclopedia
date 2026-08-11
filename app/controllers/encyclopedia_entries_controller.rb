class EncyclopediaEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_illustration, only: %i[create destroy]

  def index
    @elements = Element.order(:atomic_number)
    @entries_by_element_id = current_user.encyclopedia_entries
                                        .includes(illustration: { image_attachment: :blob })
                                        .index_by(&:element_id)
  end

  def create
    entry = current_user.encyclopedia_entries.find_or_initialize_by(element: @illustration.element)
    entry.illustration = @illustration

    if entry.save
      respond_with_entry_button(entry, "推し元素図鑑に登録しました。")
    else
      redirect_back fallback_location: illustration_path(@illustration), alert: entry.errors.full_messages.to_sentence
    end
  end

  def destroy
    entry = current_user.encyclopedia_entries.find_by!(element: @illustration.element, illustration: @illustration)
    entry.destroy!

    respond_with_entry_button(nil, "推し元素図鑑から解除しました。")
  end

  private

  # 非公開イラストは、投稿者本人であっても推し登録の対象にしない。
  def set_illustration
    @illustration = Illustration.published.find(params[:illustration_id])
  end

  # Turbo操作時は、押下した推し登録ボタンだけを最新の状態へ置き換える。
  def respond_with_entry_button(entry, notice)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@illustration, :encyclopedia_entry_button),
          partial: "encyclopedia_entries/button",
          locals: { illustration: @illustration, entry: entry }
        )
      end
      format.html { redirect_back fallback_location: illustration_path(@illustration), notice: notice }
    end
  end
end
