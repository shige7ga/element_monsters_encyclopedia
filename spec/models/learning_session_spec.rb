require "rails_helper"

RSpec.describe GameSession, type: :model do
  it "ユーザーと結果があれば有効である" do
    expect(build(:game_session)).to be_valid
  end

  it "正解数が問題数を超える場合は無効である" do
    learning_session = build(:game_session, score: 11, total_questions: 10)

    expect(learning_session).not_to be_valid
    expect(learning_session.errors[:score]).to include("は問題数以下にしてください")
  end

  it "ユーザーを削除すると学習履歴も削除される" do
    learning_session = create(:game_session)

    expect { learning_session.user.destroy! }.to change(described_class, :count).by(-1)
  end
end
