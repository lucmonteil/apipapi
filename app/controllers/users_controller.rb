class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :clean_show]

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

      service = request.service

      if service.class == Ride

        ride = service

        if ride.start_address

          start_address = ride.start_address

          @items << {
            class: start_address.class,
            instance: start_address,
            to_or_from: "from",
            created_at: start_address.created_at
          }
        end

        if ride.end_address

          end_address = ride.end_address

          @items << {
            class: end_address.class,
            instance: end_address,
            to_or_from: "to",
            created_at: end_address.created_at
          }
        end
      end
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
    @users = User.where.not('phone_number' => nil).order("created_at DESC")
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)

    redirect_to user_path(@user)
  end

  private

  def user_params
    params.require(:user).permit(:phone_number)
  end
end
