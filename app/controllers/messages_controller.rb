class MessagesController < ApplicationController

  #vérifier le skip_before_action (skip la vérification de l'auth token)
  skip_before_action :verify_authenticity_token

  #skip l'auth token pour Devise
  skip_before_action :authenticate_user!, only: [:index, :create, :new]


  def new
    @message = Message.new
  end

  def create
    # on verifie si c'est un vrai sms ou pas avec les l'existence de params["Body"]
    # l'interface web permet aussi de générer des fakes réponses
    if params["Body"]
      @message_body = params["Body"]
      @sender = true
      @user = User.find_by_phone_number(params["From"])
    else
      @message_body = params[:message][:body]
      @sender = params[:message][:sender]
      @user = User.find_by_phone_number(params[:message][:user])
    end
    create_message(@sender)
    redirect_to user_path(@user)
  end

  def reply
    boot_twilio
    @message_body = "Hello world!"
    sms = @client.messages.create(
      from: ENV['TWILIO_NUMBER'],
      to: @user.phone_number,
      body: body
    )
    create_message(false)
  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
  end

  def create_message
    Message.create(body: @message_body, user: @user, sender: @sender)
  end
end
