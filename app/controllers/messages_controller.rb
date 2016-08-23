class MessagesController < ApplicationController

  #vérifier le skip_before_action (skip la vérification de l'auth token)
  skip_before_action :verify_authenticity_token

  #skip l'auth token pour Devise
  skip_before_action :authenticate_user!, only: [:index, :create, :new]


  def new
    # sender: true pour selectionner la checkbox par défaut
    @message = Message.new
  end

  def create

    # on verifie si c'est un vrai sms ou pas avec les l'existence de params["Body"]
    if params["Body"]
      @message_body = params["Body"]
      @phone_number = params["From"]
    else
      # Faux sms
      @message_body = "Test: " + params[:message][:body]
      @phone_number = params[:message][:user]
    end

    # parsing
    if @start_address && @end_address
      @parsing = MessageParser.new(@message_body).parse_for_address
      @sender = true
    else
      @parsing = MessageParser.new(@message_body).parse_for_address
      @sender = true
    end

    # création de l'utilisateur s'il n'existe pas
    unless @user = User.find_by_phone_number(@phone_number)
      @user = User.create({
                email: "#{@phone_number}@apipapi.com",
                password: Random.new_seed,
                phone_number: @phone_number,
                first_name: "UNKNOWN"
              })
    end

    # sauvegarde du message
    create_message

    @start_address = @parsing[:start_address]
    @end_address = @parsing[:end_address]

    @start_address_reverse = @parsing[:start_address_reverse]
    @end_address_reverse = @parsing[:end_address_reverse]


    #exemple de réponse
    if @start_address_reverse && @end_address_reverse
      @message_body = "Un Uber arrive au #{@start_address_reverse.formatted_address} pour le #{@end_address_reverse.formatted_address}"
      create_ride
    elsif @start_address_reverse
      @message_body = "Un Uber arrive au #{@start_address_reverse.formatted_address}, pourriez-vous donner l'adresse d'arrivée au chauffeur ?"
      create_ride
    elsif @end_address_reverse
      @message_body = "Pourriez-vous renvoyer l'adress de départ avec plus de détail (code postal par exemple) ?"
      # l'échange n'est pas terminé, il y a besoin d'un nouveau sms
    elsif
      @message_body = "Pourriez-vous renvoyer les adresses, avec plus de détail..."
      # l'échange n'est pas terminé, il y a besoin d'un nouveau sms
    end

    if params["Body"]
      #envoit d'une réponse qu'aux vrais numéros, l'enregristement se fait dans le reply
      reply
    else
      #sauvegarde de la réponse sans l'envoyer
      @message_body = "Test : " + @message_body
      @sender = false
      create_message
    end

    redirect_to user_path(@user)
  end

  private

  def reply
    @sender = false
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
    @apipapi_phone_number = ENV['TWILIO_NUMBER']

    sms = @client.messages.create(
            from: @apipapi_phone_number,
            to: @phone_number,
            body: @message_body
          )

    create_message
  end

  def create_message
    Message.create(body: @message_body, user: @user, sender: @sender)
  end

  def create_ride
    @ride = Ride.create(user: @user, status: "pending", start_address_id: @start_address.id, end_address_id: @end_address.id)
  end
end
