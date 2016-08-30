class MessagesController < ApplicationController

  #vérifier le skip_before_action (skip la vérification de l'auth token)
  skip_before_action :verify_authenticity_token

  #skip l'auth token pour Devise
  skip_before_action :authenticate_user!, only: [:index, :create, :new, :receive_sms]

  def new
    @message = Message.new
  end

  # Methode pour les sms test
  def create
    # les messages sont des tests
    @test = true
    @body = params[:message][:body]
    @phone_number = params[:message][:user]
    # création de l'utilisateur s'il n'existe pas
    # sauvegarde du message
    # parsing
    # répartition vers la bonne methode
    set_user_create_message_parse_and_point

    # Respond to remote messages from interface_path --> dynamically load messages
    respond_to do |format|
      if @message.save
        format.html { redirect_to interface_path(@message)}
        format.js
      else
        format.html { render 'clean_show'}
        format.js
      end
    end
  end

  # Idem pour les vrais sms
  def receive_sms
    @test = false
    @body = params["Body"]
    @phone_number = params["From"]
    set_user_create_message_parse_and_point
  end

  private

  def set_user_create_message_parse_and_point
    create_user unless @user = User.find_by_phone_number(@phone_number)
    # le message vient de l'utilisateur
    @sender = true
    @message_body = @body
    create_message
    parse_and_point
  end

  # interprète le corps parsé et renvoit vers la bonne méthode
  def parse_and_point
    @reply_message_body = MessageParser.new(@message_body, @user).reply

    # enregistrement du message
    @sender = false
    @message_body = @reply_message_body
    create_message

    # réponse si le message n'est pas un test
    reply unless @test

    redirect_to user_path(@user)
  end

  # envoit d'un message à l'utilisateur et sauvegarde du message
  def reply
    # envoit du message avec Twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
    @apipapi_phone_number = ENV['TWILIO_NUMBER']
    sms = @client.messages.create(
            from: @apipapi_phone_number,
            to: @phone_number,
            body: @reply_message_body
          )
  end

  def create_user
    @user = User.create({
              email: "#{@phone_number.split(" ").join}@apipapi.com",
              password: Random.new_seed,
              phone_number: @phone_number,
              # le nom de l'utilisateur est set à UNKNOWN pour l'utiliser dans les vues
              first_name: "UNKNOWN"
            })
  end

  def create_message
    if @test
      Message.create(body: "Test : " + @message_body, user: @user, sender: @sender)
    else
      Message.create(body: @message_body, user: @user, sender: @sender)
    end
  end
end
