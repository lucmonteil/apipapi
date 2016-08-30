class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :interface]

  def home
  end

  def interface
    @message = Message.new
    # TODO - Set this to an actual user
    @user = User.find(params[:id])
    @messages = @user.messages.sort_by { |message| message.created_at }
  end

end
