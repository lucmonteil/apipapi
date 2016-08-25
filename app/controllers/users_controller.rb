class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def show
    @user = User.find(params[:id])
    @messages = Message.where(user: @user).order("created_at ASC")
    @message = Message.new
  end

  def index
    @users = User.order("created_at DESC")
  end
end
