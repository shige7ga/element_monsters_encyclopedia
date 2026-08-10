require "rails_helper"

RSpec.describe "Learning", type: :request do
  let!(:elements) { create_list(:element, 10) }

  before do
    allow_any_instance_of(LearningController).to receive(:random_question_ids).and_return(elements.map(&:id))
  end

  it "重複なしで10問出題し、正しい元素名を選ぶと正解になる" do
    question_symbols = answer_all_questions_correctly

    expect(question_symbols).to contain_exactly(*elements.map(&:symbol))
    expect(question_symbols.uniq.length).to eq(10)
    expect(response).to redirect_to(learning_result_path)

    follow_redirect!
    expect(response.body).to include("10 / 10", "正答率 100%")
  end

  it "誤った元素名を選ぶと不正解と正しい元素記号・元素名を表示する" do
    get learning_path
    question = displayed_question
    incorrect_choice = elements.find { |element| element != question }

    post learning_answer_path, params: { element_id: incorrect_choice.id }
    follow_redirect!

    expect(response.body).to include("不正解", "#{question.symbol}（#{question.name}）")
  end

  it "公開済みイラストがある元素では紐付くイラストを表示する" do
    illustration = create(:illustration, element: elements.first, published: true, monster_name: "水素モンスター")

    get learning_path

    expect(response.body).to include("水素モンスター")
    expect(response.body).not_to include("イラスト未投稿")
    expect(illustration.element_id).to eq(elements.first.id)
  end

  it "公開済みイラストがない元素では未投稿メッセージを表示する" do
    get learning_path

    expect(response.body).to include("イラスト未投稿")
  end

  it "ログイン時は完了した結果を保存する" do
    sign_in(create(:user))

    expect { answer_all_questions_correctly }.to change(GameSession, :count).by(1)
    expect(GameSession.last).to have_attributes(score: 10, total_questions: 10)
  end

  it "未ログイン時は完了した結果を保存しない" do
    expect { answer_all_questions_correctly }.not_to change(GameSession, :count)
  end

  private

  def answer_all_questions_correctly
    question_symbols = []

    10.times do |index|
      get learning_path
      question = displayed_question
      question_symbols << question.symbol

      post learning_answer_path, params: { element_id: question.id }
      follow_redirect!
      expect(response.body).to include("正解！", "#{question.symbol}（#{question.name}）")

      post learning_next_path
      follow_redirect! unless index == 9
    end

    question_symbols
  end

  def displayed_question
    symbol = response.body.match(/data-learning-question-symbol="([^"]+)"/)[1]
    Element.find_by!(symbol: symbol)
  end
end
