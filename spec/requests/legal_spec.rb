require "rails_helper"

RSpec.describe "Legal pages", type: :request do
  let(:contact_form_url) { "https://forms.gle/uwgDobjZ3MY72uiz7" }

  it "利用規約を全文表示し、お問い合わせURLをクリック可能にする" do
    get terms_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "元素モンスターズ図鑑 利用規約",
      "第4条（AIを利用した画像について）",
      "第15条（お問い合わせ）",
      "制定日：2026年8月11日",
      %Q(href="#{contact_form_url}"),
      'target="_blank"',
      'rel="noopener noreferrer"'
    )
  end

  it "プライバシーポリシーを全文表示し、お問い合わせURLをクリック可能にする" do
    get privacy_policy_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "元素モンスターズ図鑑 プライバシーポリシー",
      "第1条（取得する情報）",
      "AI利用の有無など、投稿時にユーザーが登録する情報",
      "第12条（お問い合わせ）",
      "制定日：2026年8月11日",
      %Q(href="#{contact_form_url}"),
      'target="_blank"',
      'rel="noopener noreferrer"'
    )
  end

  it "フッターから利用規約、プライバシーポリシー、お問い合わせへ遷移できる" do
    get root_path

    expect(response.body).to include(
      'href="/terms"',
      'href="/privacy_policy"',
      %Q(href="#{contact_form_url}"),
      'target="_blank"',
      'rel="noopener noreferrer"'
    )
  end
end
