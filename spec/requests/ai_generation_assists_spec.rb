require "rails_helper"

RSpec.describe "AiGenerationAssists", type: :request do
  let(:element) do
    create(
      :element,
      name: "炭素",
      symbol: "C",
      atomic_number: 6,
      english_name: "Carbon",
      common_state: "固体",
      description: "多彩な化合物をつくる元素です。"
    )
  end

  let(:valid_params) do
    {
      ai_generation_assist: {
        element_id: element.id,
        atmosphere: "かわいい",
        monster_shape: "スライム型",
        main_color: "黒",
        sub_color: "緑",
        motif: "妖精",
        personality: "好奇心旺盛",
        related_words: "鉱石、森",
        additional_request: "つやのある質感にしてください"
      }
    }
  end

  it "AI生成アシスト画面を表示できる" do
    get ai_generation_assist_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AI生成アシスト", "元素", "雰囲気", "モンスターの形", "プロンプトを生成する", "使い方を見る")
    expect(response.body).to include('name="ai_generation_assist[element_id]"')
  end

  it "入力値から元素情報を含む、イラスト用と名前提案用の別々のプロンプトを生成できる" do
    post ai_generation_assist_path, params: valid_params

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "イラスト生成用プロンプト",
      "モンスター名提案用プロンプト",
      "炭素",
      "元素記号「C」",
      "原子番号6",
      "スライム型",
      "名前を5案",
      "コピーしました",
      "ChatGPTで作成する"
    )
    expect(response.body.scan(">コピー<")).to have_attributes(length: 2)
    expect(response.body).to include('target="_blank"', 'rel="noopener noreferrer"')
  end

  it "完成したイラストの投稿導線で選択した元素を投稿画面へ引き継げる" do
    user = create(:user)
    sign_in(user)

    post ai_generation_assist_path, params: valid_params
    expect(response.body).to include(new_illustration_path(element_id: element.id))

    get new_illustration_path(element_id: element.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<option selected=\"selected\" value=\"#{element.id}\"")
  end

  it "元素未選択ではプロンプトを生成しない" do
    post ai_generation_assist_path, params: { ai_generation_assist: valid_params[:ai_generation_assist].merge(element_id: "") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("元素 を選択してください")
    expect(response.body).not_to include("イラスト生成用プロンプト")
  end

  it "使い方ページを表示できる" do
    get ai_generation_assist_how_to_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AI生成アシストの使い方", "元素やモンスターの特徴を選ぶ", "元素モンスターズ図鑑へ戻って投稿する")
  end
end
