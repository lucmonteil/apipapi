class MessageParser

  def initialize(message_body, user)
    @message_body = message_body
    @user = user
  end

  def point_to_service
    if @user.requests.empty? || @user.requests.last.wait_message
    # check si c'est la première demande du user
      create_request
      # si la request est pour une ride on crée la ride
      create_ride
      @request.service = @ride
    else
    # check si la dernière request attend une reponse
      @request = @user.requests.last
      # si la request est pour une ride
      @ride = @request.service
    end

    # si la request est pour une ride
    return conversation_ride
  end

  def conversation_ride
    # TODO créer la colonne waiting_for_sms et set la valeur à false quand
    # le service a été rendu ou qu'un temps X c'est passé depuis le dernier sms
    if @ride.end_address
      parse_for_start_address
      geocode(@found_start_address, "start")
    else
      parse_for_start_and_end_address
      geocode(@found_start_address, "start")
      geocode(@found_end_address, "end")
    end

    if @ride.start_address = @start_address
      @ride.save
    end

    if @ride.end_address = @end_address
      @ride.save
    end

    # réponses en fonction de la situation
    if @ride.start_address && @ride.end_address
      @request.wait_message = false
      @answer_body_message = "Un Uber arrive au #{@start_address_nice} pour le #{@end_address_nice}"

    elsif @ride.start_address
      @request.wait_message = false
      @answer_body_message = "Un Uber arrive au #{@start_address_nice}."

    elsif @ride.end_address
      @answer_body_message = "Pourriez-vous renvoyer l'adresse de départ svp ? (L'adresse d'arrivée est #{@end_address_nice}) "

    else
      @answer_body_message = "Pourriez-vous renvoyer une adresse d'arrivée et une addresse de départ svp ?"

    end

    @request.save

    return @answer_body_message
  end

  private

  # création du "service ride"
  def create_request
    @request = Request.create(wait_message: true, user: @user)
  end

  # création du "service ride", à balancer dans Uber_service
  def create_ride
    @ride = Ride.create(status: "pending")
  end

  def geocode(searched_address, prefix)
    address = Address.new(query: searched_address)
    address.validate # triggers geocoder
    if address.save
      lat = instance_variable_set("@#{prefix}_latitude", address.latitude)
      lng = instance_variable_set("@#{prefix}_longitude", address.longitude)
      instance_variable_set("@#{prefix}_address_nice", Geocoder.search("#{lat},#{lng}")[0].formatted_address)
      instance_variable_set("@#{prefix}_address", address)
    end
  end

  # ces methodes seront refaites dans RECAST.AI
  def parse_for_start_and_end_address
    # ici la pire AI du monde !
    split = @message_body.split(";")
    @found_start_address = split[0]
    @found_end_address = split[1]

    # refactorisation pour le kiff

  end

  def parse_for_start_address
    # ici même pas de split, on prend toute la string
    @found_start_address = @message_body
  end
end
