require "rails_helper"
require "tempfile"

RSpec.describe "Illustrations", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:element) { create(:element) }
  let!(:published_illustration) { create(:illustration, user: owner, element: element, monster_name: "公開作品", published: true) }
  let!(:private_illustration) { create(:illustration, user: owner, element: element, monster_name: "非公開作品", published: false) }

  it "未ログイン時は公開作品だけを一覧表示し、投稿画面はログインを要求する" do
    get illustrations_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("公開作品", "イラスト集", "周期表", "ILLUSTRATION GALLERY", "元素モンスターを見て、あなたの推し元素を探そう")
    expect(response.body).not_to include("非公開作品")

    get new_illustration_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "投稿・編集フォームにモンスター名、説明、明示した送信ボタンを表示する" do
    sign_in(owner)

    get new_illustration_path
    expect(response.body).to include("モンスター名", "説明（モンスターの特徴・元素の覚え方など）", "投稿する")

    get edit_illustration_path(published_illustration)
    expect(response.body).to include("更新する")
  end

  it "element_id付きの投稿画面では対象元素を初期選択する" do
    sign_in(owner)

    get new_illustration_path(element_id: element.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<option selected=\"selected\" value=\"#{element.id}\"")
  end

  it "詳細と一覧でモンスター名・説明を表示し、画像をobject-containで収める" do
    get illustration_path(published_illustration)

    expect(response.body).to include("公開作品", published_illustration.description, "object-contain", "md:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]")
    expect(response.body).not_to include("ILLUSTRATION", ">公開<")

    get illustrations_path
    expect(response.body).to include("aspect-square", "aspect-ratio: 1 / 1;", "max-h-full", "max-w-full", "width: auto; height: auto; max-width: 100%; max-height: 100%; object-fit: contain; object-position: center;")
  end

  it "投稿者は自分の非公開作品を閲覧できるが、他人は閲覧できない" do
    sign_in(owner)
    get illustrations_path
    expect(response.body).to include("非公開作品")

    get illustration_path(private_illustration)
    expect(response).to have_http_status(:ok)

    sign_out(owner)
    get illustration_path(private_illustration)
    expect(response).to redirect_to(illustrations_path)
  end

  it "投稿者以外の編集用URLへのアクセスを拒否する" do
    sign_in(other_user)

    get edit_illustration_path(published_illustration)

    expect(response).to have_http_status(:not_found)
  end

  it "投稿者以外の削除用URLへのアクセスを拒否する" do
    sign_in(other_user)

    delete illustration_path(published_illustration)

    expect(response).to have_http_status(:not_found)
    expect(Illustration).to exist(published_illustration.id)
  end

  it "ログインユーザーは画像付きのイラストを投稿できる" do
    sign_in(owner)

    Tempfile.create([ "illustration", ".png" ]) do |file|
      file.binmode
      file.write("image data")
      file.rewind
      upload = Rack::Test::UploadedFile.new(file.path, "image/png")

      post illustrations_path, params: {
        illustration: {
          element_id: element.id,
          image: upload,
          monster_name: "新しい投稿",
          description: "説明",
          published: "1"
        }
      }
    end

    illustration = Illustration.find_by!(monster_name: "新しい投稿")
    expect(response).to redirect_to(illustration_path(illustration))
    expect(illustration.user).to eq(owner)
    expect(illustration.description).to eq("説明")
    expect(illustration.image).to be_attached
  end

  it "投稿者ページには公開作品だけを表示し、本人のページには非公開作品も表示する" do
    get user_path(owner)
    expect(response.body).to include("公開作品")
    expect(response.body).not_to include("非公開作品")

    sign_in(owner)
    get mypage_path
    expect(response.body).to include("公開作品", "非公開作品")
  end
end
