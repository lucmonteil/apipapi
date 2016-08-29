class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def show

    @message = Message.new
    @user = User.find(params[:id])

    @items = []

    @user.messages.each do |message|

      @items << {
        class: message.class,
        instance: message,
        created_at: message.created_at
      }
    end

    @user.requests.each do |request|

      @items << {
        class: request.class,
        instance: request,
        created_at: request.created_at
      }

    end

    @items = @items.sort_by { |item| item[:created_at] }

    # @messages = Message.where(user: @user).order("created_at ASC")
  end

  def index
    @users = User.order("created_at DESC")
  end
end
