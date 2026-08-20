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
        motif: "妖精",
        personality: "好奇心旺盛",
        additional_request: "つやのある質感にしてください"
      }
    }
  end

  it "かんたん元素モンスター作成アシスト画面を表示でき、必要な選択項目だけを表示する" do
    get ai_generation_assist_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "かんたん元素モンスター作成アシスト",
      "気軽にイラストを投稿して元素を楽しみましょう！",
      "元素",
      "雰囲気",
      "モンスターの形",
      "メインカラー",
      "モチーフ",
      "印象・性格",
      "キーワード・こだわり",
      "キーワードだけでもOK",
      "プロンプトを生成する",
      "使い方を見る"
    )
    expect(response.body).to include('name="ai_generation_assist[element_id]"')
    expect(response.body).not_to include("サブカラー", "関連ワード", "AI APIへの送信や内容の保存は行いません。", 'value="その他"')

    document = Nokogiri::HTML(response.body)
    main_color_select = document.at_css("select[name='ai_generation_assist[main_color]']")
    expect(main_color_select.css("option").map(&:text)).to eq([ "選択してください", "赤", "青", "緑", "黄", "紫", "白", "黒", "金" ])
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
      "メインカラー：黒",
      "印象・性格：好奇心旺盛",
      "キーワード・こだわり：つやのある質感にしてください",
      "名前を5案",
      "プロンプト完了",
      "画像に書く情報ではなく、モンスターデザインを考えるための参考情報",
      "元素名・原子番号・英名・常温での状態・元素の説明文を画像内に文字として描画しないでください",
      "元素記号は、紋章・装飾・鎧・持ち物・球体などデザインの一部に自然に組み込んでも構いませんが、使用は必須ではありません",
      "著作権・商標権・肖像権など第三者の権利を侵害せず",
      "特定のクリエイターの作品そのものを再現したり",
      "過度に暴力的、残虐、グロテスク、性的、その他刺激の強すぎる表現は避け",
      "コピーしました",
      "ChatGPTで作成する"
    )
    expect(response.body.scan(">コピー<")).to have_attributes(length: 2)

    document = Nokogiri::HTML(response.body)
    chatgpt_links = document.css("a[href='https://chatgpt.com/']")
    post_links = document.css("a").select { |link| link.text.include?("完成したイラストを投稿する") }

    expect(chatgpt_links).to have_attributes(length: 1)
    expect(chatgpt_links.first["target"]).to eq("_blank")
    expect(chatgpt_links.first["rel"]).to eq("noopener noreferrer")
    expect(post_links).to have_attributes(length: 1)
    expect(post_links.first["class"]).to include("bg-cyan-400")
    expect(response.body).not_to include("プロンプトを生成しました")
  end

  it "完成したイラストの投稿導線で元素とAI生成を投稿画面へ引き継げる" do
    user = create(:user)
    sign_in(user)

    post ai_generation_assist_path, params: valid_params
    document = Nokogiri::HTML(response.body)
    post_links = document.css("a").select { |link| link.text.include?("完成したイラストを投稿する") }
    expect(post_links.map { |link| link["href"] }).to include(new_illustration_path(element_id: element.id, from_ai_assist: 1))

    get new_illustration_path(element_id: element.id, from_ai_assist: 1)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<option selected=\"selected\" value=\"#{element.id}\"")
    creation_type = Nokogiri::HTML(response.body).at_css("input[name='illustration[creation_type]'][value='ai_generated']")
    expect(creation_type["checked"]).to eq("checked")
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
    expect(response.body).to include("かんたん元素モンスター作成アシストの使い方", "元素やモンスターの特徴を選ぶ", "元素モンスターズ図鑑へ戻って投稿する")
  end

  it "使い方ページへのリンクを新しいタブで開く" do
    get ai_generation_assist_path

    document = Nokogiri::HTML(response.body)
    how_to_link = document.at_css("a[href='#{ai_generation_assist_how_to_path}']")

    expect(how_to_link["target"]).to eq("_blank")
    expect(how_to_link["rel"]).to eq("noopener noreferrer")
  end
end
