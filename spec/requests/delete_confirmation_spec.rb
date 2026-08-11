require "rails_helper"
require "cgi"

RSpec.describe "Delete confirmation", type: :request do
  let(:owner) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:managed_user) { create(:user) }
  let(:illustration) { create(:illustration, user: owner) }

  it "削除確認の文言とキャンセル・削除操作を全ページ共通で表示する" do
    sign_in(owner)

    get illustration_path(illustration)
    expect(response.body).to include(
      "本当に削除しますか？削除したデータは元に戻せません。",
      'data-action="delete-confirmation#open"',
      'data-delete-confirmation-url-param="/illustrations/' + illustration.id.to_s + '"',
      "data-delete-confirmation-csrf-token-param",
      'data-delete-confirmation-target="csrfToken"',
      "キャンセル",
      "削除する"
    )

    get edit_user_registration_path
    expect(response.body).to include('data-action="delete-confirmation#open"', 'data-delete-confirmation-url-param="/users"')

    sign_out(owner)
    managed_user
    sign_in(admin)

    get admin_users_path
    expect(response.body).to include('data-action="delete-confirmation#open"', 'data-delete-confirmation-url-param="/admin/users/' + managed_user.id.to_s + '"')

    get admin_illustrations_path
    expect(response.body).to include('data-action="delete-confirmation#open"', 'data-delete-confirmation-url-param="/admin/illustrations/' + illustration.id.to_s + '"')
  end

  it "削除先専用のCSRF tokenで確認後のDELETEを実行できる" do
    original_setting = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    managed_user
    sign_in(admin)

    get admin_users_path
    document = Nokogiri::HTML(response.body)
    delete_button = document.css("button[data-delete-confirmation-url-param]").find do |button|
      button["data-delete-confirmation-url-param"] == admin_user_path(managed_user)
    end
    csrf_token = CGI.unescapeHTML(delete_button["data-delete-confirmation-csrf-token-param"])

    expect { delete admin_user_path(managed_user), params: { authenticity_token: csrf_token } }.to change(User, :count).by(-1)
    expect(response).to redirect_to(admin_users_path)
  ensure
    ActionController::Base.allow_forgery_protection = original_setting
  end
end
