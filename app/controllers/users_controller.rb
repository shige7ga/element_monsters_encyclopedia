class UsersController < ApplicationController
  before_action :authenticate_user!, only: :mypage

  def mypage
    @user = current_user
    @profile_owner = true
    @active_tab = profile_tab
    load_profile_stats
    load_illustrations
    render :show
  end

  def show
    @user = User.find(params[:id])
    @profile_owner = current_user == @user
    @active_tab = profile_tab
    load_profile_stats if @profile_owner
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
        @user.liked_illustrations.visible_to(viewer).includes(:user, :element, :likes).with_attached_image.order(created_at: :desc).page(params[:page]).per(12)
      else
        @user.illustrations.visible_to(viewer).includes(:user, :element, :likes).with_attached_image.order(created_at: :desc).page(params[:page]).per(12)
      end
  end

  # 学習履歴は本人だけが確認できるため、マイページ表示時だけ集計する
  def load_profile_stats
    highest_score = @user.game_sessions.order(score: :desc, total_questions: :desc, created_at: :desc).pick(:score, :total_questions)

    @profile_stats = {
      illustrations_count: @user.illustrations.count,
      game_sessions_count: @user.game_sessions.count,
      highest_score: highest_score,
      encyclopedia_entries_count: @user.encyclopedia_entries.count
    }
  end
end
