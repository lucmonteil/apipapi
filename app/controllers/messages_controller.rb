class MessagesController < ApplicationController

  #vérifier le skip_before_action (skip la vérification de l'auth token)
  skip_before_action :verify_authenticity_token

  #skip l'auth token pour Devise
  skip_before_action :authenticate_user!, only: [:index, :create, :new]


  def new
    @message = Message.new(sender: true)
  end

  def create
    @sender = true
    # on verifie si c'est un vrai sms ou pas avec les l'existence de params["Body"]
    # l'interface web permet aussi de générer des fakes réponses
    if params["Body"]
      @message_body = params["Body"]
      @phone = params["From"]
    else
      @message_body = params[:message][:body]
      @sender = params[:message][:sender] ==  "0" ? false : true
      @phone = params[:message][:user]
    end
    unless @user = User.find_by_phone_number(@phone)
      @user = User.new
      @user.email = "#{@phone}@apipapi.com"
      @user.password = Random.new_seed
      @user.phone_number = @phone
      @user.first_name = "TEST"
      @user.save
    end
    create_message
    respond_to do |format|
      format.html { redirect_to user_path(@user) }
      format.js  # <-- will render `app/views/reviews/create.js.erb`
    end
  end

  def reply
    @sender = false
    boot_twilio
    @message_body = "Hello world!"
    sms = @client.messages.create(
      from: ENV['TWILIO_NUMBER'],
      to: @phone,
      body: body
    )
    create_message
  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
  end

  def create_message
    @message = Message.create(body: @message_body, user: @user, sender: @sender)
  end
end
