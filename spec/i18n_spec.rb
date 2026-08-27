require "rails_helper"

RSpec.describe "日本語i18n" do
  it "日本語を既定localeとして使用する" do
    expect(I18n.default_locale).to eq(:ja)
    expect(I18n.locale).to eq(:ja)
  end

  it "モデル名、属性名、enum表示名を日本語で解決する" do
    expect(Illustration.model_name.human).to eq("イラスト")
    expect(Illustration.human_attribute_name(:monster_name)).to eq("モンスター名")
    expect(I18n.t("enums.illustration.creation_type.ai_generated")).to eq("AI生成")
  end

  it "独自バリデーションメッセージを日本語で解決する" do
    illustration = build(:illustration, element: nil)

    expect(illustration).not_to be_valid
    expect(illustration.errors.full_messages).to include("対象元素 を選択してください")
  end

  it "Deviseの認証失敗メッセージを日本語で解決する" do
    expect(I18n.t("devise.failure.invalid")).to eq("メールアドレスまたはユーザーID、もしくはパスワードが正しくありません。")
  end

  it "アプリケーションコードが参照する静的な翻訳キーをすべて定義する" do
    keys = Dir[Rails.root.join("app/**/*.{rb,erb}")].flat_map do |file|
      File.read(file).scan(/(?:\bt|I18n\.t)\("([^"]+)"\)/).flatten
    end.uniq

    missing_keys = keys.reject { |key| I18n.exists?(key, :ja) }

    expect(missing_keys).to be_empty
  end
end
