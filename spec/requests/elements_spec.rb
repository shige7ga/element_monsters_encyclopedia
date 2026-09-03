require "rails_helper"
RSpec.describe "Elements", type: :request do
  let!(:element) { create(:element, atomic_number: 1_000, symbol: "T1000", name: "水素", english_name: "Hydrogen", common_state: "気体", period: 1, group_number: 18) }
  let!(:lanthanide) { create(:element, atomic_number: 57, symbol: "La", name: "ランタン", english_name: "Lanthanum", common_state: "固体", period: 6, group_number: nil) }
  let!(:actinide) { create(:element, atomic_number: 89, symbol: "Ac", name: "アクチニウム", english_name: "Actinium", common_state: "固体", period: 7, group_number: nil) }
  it "周期表と元素詳細を表示し、元素別AI作成と投稿の導線を表示する" do
    get elements_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("周期表", "イラスト集", "水素の情報を表示", 'href="/illustrations"')
    expect(response.body.index("PERIODIC TABLE")).to be < response.body.index("気になる元素記号を選んで、詳細を調べてみよう。")
    expect(response.body).to include('class="mt-1 flex justify-center"')
    expect(response.body).to include('data-action="modal#open periodic-table#close"', 'data-modal-dialog-param="registration"')

    get element_path(element)
    expect(response.body).to include(
      "この元素モンスターを作る",
      "href=\"/ai_generation_assist?element_id=#{element.id}\"",
      "この元素を投稿する",
      'data-action="modal#open"',
      'data-modal-dialog-param="registration"'
    )

    sign_in(create(:user))
    get elements_path
    expect(response.body).to include('data-action="periodic-table#post"', "data-element-post-url=\"/illustrations/new?element_id=#{element.id}\"")
    illustration = create(:illustration, element: element, monster_name: "水素の公開イラスト", published: true)
    get element_path(element)
    expect(response.body).to include("水素", "Hydrogen", "18族1周期", "常温での状態", "気体", "水素の公開イラスト", "ILLUSTRATIONS", "おすすめ", "新着", "人気", "button-interaction", 'data-turbo="false"', "href=\"/ai_generation_assist?element_id=#{element.id}\"", "href=\"/illustrations/new?element_id=#{element.id}\"")
    expect(response.body).to include('md:grid-cols-[fit-content(32rem)_minmax(0,1fr)]', 'break-words', '基本データ', 'flex w-full flex-nowrap', 'whitespace-nowrap')
    expect(response.body).to include(illustration.element.symbol)
    expect(response.body).not_to include("作品数", "水素のイラスト")
  end

  it "通常元素を同じ通常色に統一し、下段系列だけの凡例を表示する" do
    get elements_path

    document = Nokogiri::HTML(response.body)
    normal_cell = document.at_css("button[aria-label='#{element.name}の情報を表示']")
    lanthanide_cell = document.at_css("button[aria-label='#{lanthanide.name}の情報を表示']")
    actinide_cell = document.at_css("button[aria-label='#{actinide.name}の情報を表示']")
    legend = document.at_css("aside[aria-label='周期表の色分け']")

    expect(normal_cell["class"]).to include("border-slate-500", "bg-slate-800", "text-slate-100")
    expect(normal_cell["class"]).not_to include("bg-cyan-300/15", "bg-violet-300/15", "bg-amber-300/15")
    expect(lanthanide_cell["class"]).to include("border-rose-300", "bg-rose-500/25", "text-rose-100")
    expect(actinide_cell["class"]).to include("border-emerald-300", "bg-emerald-500/25", "text-emerald-100")
    expect(legend.text).to include("ランタノイド", "アクチノイド")
  end
  it "元素詳細の関連イラストを12件ずつ表示し、並び替え条件をページ移動後も維持する" do
    13.times do |index|
      illustration = create(:illustration, element: element, monster_name: "元素ページ作品#{index + 1}", created_at: (index + 1).minutes.ago)
      create_list(:like, index == 10 ? 2 : 1, illustration: illustration)
    end

    get element_path(element, page: 2)

    expect(response.body).to include("2 / 2", 'href="/elements/' + element.id.to_s + '?page=1"')

    get element_path(element, sort: "newest", page: 2)

    expect(response.body).to include("2 / 2", "元素ページ作品1")
    expect(response.body).to include('href="/elements/' + element.id.to_s + '?page=1&amp;sort=newest"')

    get element_path(element, sort: "popular", page: 2)

    expect(response.body).to include("2 / 2", "元素ページ作品1")
    expect(response.body).to include('href="/elements/' + element.id.to_s + '?page=1&amp;sort=popular"')
  end

  it "元素詳細内のイラストをおすすめ・新着・人気順で切り替えられる" do
    owner = create(:user)
    newest_illustration = create(:illustration, element: element, monster_name: "新着イラスト", created_at: 1.hour.ago)
    popular_illustration = create(:illustration, element: element, monster_name: "人気イラスト", created_at: 2.hours.ago)
    private_illustration = create(:illustration, user: owner, element: element, monster_name: "非公開イラスト", published: false)
    create_list(:like, 2, illustration: popular_illustration)

    sign_in(owner)
    get element_path(element)

    sort_links = Nokogiri::HTML(response.body).css('nav[aria-label="元素イラスト一覧切替"] a')

    expect(sort_links.map(&:text)).to eq(%w[おすすめ 新着 人気])
    expect(sort_links.find { |link| link.text == "おすすめ" }["aria-current"]).to eq("page")
    expect(sort_links.find { |link| link.text == "新着" }["href"]).to eq("/elements/#{element.id}?sort=newest")
    expect(response.body).not_to include(private_illustration.monster_name)

    get element_path(element, sort: "newest")
    expect(response.body).to include('aria-current="page"', "新着イラスト", "人気イラスト")
    expect(response.body).to include(private_illustration.monster_name)
    expect(response.body.index("新着イラスト")).to be < response.body.index("人気イラスト")

    get element_path(element, sort: "popular")
    expect(response.body).to include('href="/elements/' + element.id.to_s + '?sort=popular"', 'aria-current="page"')
    expect(response.body.index("人気イラスト")).to be < response.body.index("新着イラスト")
  end
end
