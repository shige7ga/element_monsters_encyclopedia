class UsersController < ApplicationController
  before_action :authenticate_user!, only: :mypage

  def mypage
    @user = current_user
    @profile_owner = true
    @active_tab = profile_tab
    load_illustrations
    render :show
  end

  def show
    @user = User.find(params[:id])
    @profile_owner = current_user == @user
    @active_tab = profile_tab
    load_illustrations
  end

  private

  # 未指定時は投稿一覧を表示し、不正な値は投稿一覧として扱う
  def profile_tab
    params[:tab] == "likes" ? "likes" : "posts"
  end

  # 本人は自分の非公開作品も確認でき、他ユーザーのページでは公開作品だけを表示する
  def load_illustrations
    viewer = @profile_owner ? current_user : nil

    @illustrations =
      if @active_tab == "likes"
        @user.liked_illustrations.visible_to(viewer).includes(:user, :element, :likes).with_attached_image.order(created_at: :desc)
      else
        @user.illustrations.visible_to(viewer).includes(:user, :element, :likes).with_attached_image.order(created_at: :desc)
      end
  end
end
