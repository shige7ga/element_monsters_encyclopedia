class HomeController < ApplicationController
  # ログイン済みユーザーにはトップ画面ではなくマイページを表示する
  before_action :redirect_authenticated_user, only: :index

  def index
  end

  private

  def redirect_authenticated_user
    redirect_to mypage_path if user_signed_in?
  end
end
