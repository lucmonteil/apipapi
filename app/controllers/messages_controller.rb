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
    @parsing = MessageParser.new(@message_body).parse_for_address
    @sender = true

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

    #exemple de réponse
    if @parsing[:start_address] && @parsing[:end_address]
      @message_body = "Un Uber arrive au #{@parsing[:start_address].formatted_address} pour le #{@parsing[:end_address].formatted_address}"
    elsif @parsing[:start_address]
      @message_body = "Un Uber arrive au #{@parsing[:start_address].formatted_address}, nous n'avons pas réussi à trouver l'address de destination, pourriez-vous la donner au chauffeur lorsqu'il arrivera svp ?"
    elsif @parsing[:end_address]
      @message_body = "Nous n'avons pas trouvé l'adresse de départ, pourriez-vous la renvoyer avec plus de détail (code postal par exemple) ?"
    elsif
      @message_body = "Mmmmh, pourriez-vous verifier les adresses, nous n'arrivons pas à les trouver..."
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
            to: phone_number,
            body: message_body
          )

    create_message
  end

  def create_message
    Message.create(body: @message_body, user: @user, sender: @sender)
  end
end
