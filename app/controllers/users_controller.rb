class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def show
    @user = User.find(params[:id])
    @messages = Message.where(user: @user).order("created_at DESC")
    @message = Message.new(sender: true)
  end

  def index
    @users = User.order("created_at ASC")
  end
end
