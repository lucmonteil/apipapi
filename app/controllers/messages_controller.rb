class MessagesController < ApplicationController

  #vérifier le skip_before_action (skip la vérification de l'auth token)
  skip_before_action :verify_authenticity_token

  #skip l'auth token pour Devise
  skip_before_action :authenticate_user!, only: [:index, :create, :new]

  def new
    @message = Message.new
  end

  # Methode pour les sms test
  def create
    # les messages sont envoyés par l'utilisateur
    @sender = true
    # les messages sont des tests
    @test = true
    @message_body = "Test: " + params[:message][:body]
    @phone_number = params[:message][:user]
    # création de l'utilisateur s'il n'existe pas
    # sauvegarde du message
    # parsing
    # répartition vers la bonne methode
    set_user_create_message_parse_and_point
  end

  # Idem pour les vrais sms
  def receive_sms
    # TO DO : créer la route pour twilio
    @sender = true
    @test = false
    @message_body = params["Body"]
    @phone_number = params["From"]
    set_user_create_message_parse_and_point
  end

  private

  def create_user
    @user = User.create({
              email: "#{@phone_number}@apipapi.com",
              password: Random.new_seed,
              phone_number: @phone_number,
              # le nom de l'utilisateur est set à UNKNOWN pour l'utiliser dans les vues
              first_name: "UNKNOWN"
            })
  end

  def create_message
    Message.create(body: @message_body, user: @user, sender: @sender)
  end

  def set_user_create_message_parse_and_point
    create_user unless = User.find_by_phone_number(@phone_number)
    create_message
    parse_and_point
  end

  # interprète le corps parsé et renvoit vers la bonne méthode
  def parse_and_point
    # création d'une course (qui ne fait rien pour l'instant)
    create_ride unless @ride
    # check si on attends une réponse, ici
    # TODO créer la colonne waiting_for_sms et set la valeur à false quand
    # le service a été rendu ou qu'un temps X c'est passé depuis le dernier sms
    if ❗@ride.waiting_for_sms && @end_address_reverse
      @parsing = MessageParser.new(@message_body).parse_for_end_address
    else
      @parsing = MessageParser.new(@message_body).parse_for_start_and_end_address
    end

    # un peu de ménage pour plus de lisibilité
    @start_address = @parsing[:start_address]
    @end_address = @parsing[:end_address]
    # ici les lat,lng réinterpretées par géocoder
    @start_address_reverse = @parsing[:start_address_reverse]
    @end_address_reverse = @parsing[:end_address_reverse]

    # réponses en fonction de la situation
    if @start_address_reverse && @end_address_reverse
      # l'échange est terminé
      ❗@ride.waiting_for_sms = false
      @message_body = "Un Uber arrive au #{@start_address_reverse.formatted_address} pour le #{@end_address_reverse.formatted_address}"
      @ride.start_address_id = @start_address.id
      @ride.end_address_id = @end_address.id
    elsif @start_address_reverse
      ❗@ride.waiting_for_sms = false
      @message_body = "Un Uber arrive au #{@start_address_reverse.formatted_address}, pourriez-vous donner l'adresse d'arrivée au chauffeur ?"
      @ride.start_address_id = @start_address.id
    elsif @end_address_reverse
      # l'échange n'est pas terminé, il y a besoin d'un nouveau sms
      ❗@ride.waiting_for_sms = true
      @message_body = "Pourriez-vous renvoyer l'adress de départ avec plus de détail (code postal par exemple) ?"
      @ride.end_address_id = @end_address.id
    else
      ❗@ride.waiting_for_sms = true
      @message_body = "Pourriez-vous renvoyer les adresses, avec plus de détail..."
    end

    # en cas de test...
    fake_reply if @test

    # ...et le contraire
    reply unless @test

    # enregistrement du message
    create_message

    redirect_to user_path(@user)
  end

  # envoit d'un message à l'utilisateur et sauvegarde du message
  def reply
    # les messages sont envoyés à l'utilisateur
    @sender = false
    # envoit du message avec Twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
    @apipapi_phone_number = ENV['TWILIO_NUMBER']
    sms = @client.messages.create(
            from: @apipapi_phone_number,
            to: @phone_number,
            body: @message_body
          )
  end

  #sauvegarde de la réponse sans l'envoyer
  def fake_reply
    @sender = false
    @message_body = "Test : " + @message_body
  end

  # création du "service ride"
  def create_ride
    @ride = Ride.create(user: @user, status: "pending")
  end
end
