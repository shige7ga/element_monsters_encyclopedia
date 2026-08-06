class UsersController < ApplicationController
  before_action :authenticate_user!, only: :mypage

  def mypage
    @user = current_user
    @profile_owner = true
    load_illustrations
    render :show
  end

  def show
    @user = User.find(params[:id])
    @profile_owner = current_user == @user
    load_illustrations
  end

  private

  def load_illustrations
    viewer = @profile_owner ? current_user : nil
    @illustrations = @user.illustrations.visible_to(viewer).includes(:element).with_attached_image.order(created_at: :desc)
  end
end
