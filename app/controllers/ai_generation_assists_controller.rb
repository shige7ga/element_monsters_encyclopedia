class AiGenerationAssistsController < ApplicationController
  def new
    @ai_generation_assist = AiGenerationAssistForm.new
  end

  def create
    @ai_generation_assist = AiGenerationAssistForm.new(ai_generation_assist_params)

    if @ai_generation_assist.valid?
      @illustration_prompt = @ai_generation_assist.illustration_prompt
      @name_prompt = @ai_generation_assist.name_prompt
      render :new
    else
      render :new, status: :unprocessable_content
    end
  end

  def how_to
  end

  private

  # プロンプトに使う値だけを受け取り、保存や外部APIへの送信は行わない。
  def ai_generation_assist_params
    params.require(:ai_generation_assist).permit(
      :element_id,
      :atmosphere,
      :monster_shape,
      :main_color,
      :motif,
      :personality,
      :additional_request
    )
  end
end
