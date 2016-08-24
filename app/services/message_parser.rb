class MessageParser

  def initialize(message_body, user)
    @message_body = message_body
    @user = user
  end

  def point
    create_request unless @request
    return ride
  end

  def ride
    # création d'une course (qui ne fait rien pour l'instant)
    waiting_sms = @request.wait_message
    # check si on attends une réponse, ici
    # TODO créer la colonne waiting_for_sms et set la valeur à false quand
    # le service a été rendu ou qu'un temps X c'est passé depuis le dernier sms
    if waiting_sms && @end_address_nice
      parse_for_end_address
    else
      parse_for_start_and_end_address
    end

    # réponses en fonction de la situation
    if @start_address_nice && @end_address_nice
      # l'échange est terminé
      waiting_sms = false
      return "Un Uber arrive au #{@start_address_nice} pour le #{@end_address_nice}"
    elsif @start_address_nice
      waiting_sms = false
      return "Un Uber arrive au #{@start_address_nice}, pourriez-vous donner l'adresse d'arrivée au chauffeur ?"
    elsif @end_address_nice
      # l'échange n'est pas terminé, il y a besoin d'un nouveau sms
      waiting_sms = true
      return "Pourriez-vous renvoyer l'adress de départ avec plus de détail (code postal par exemple) ?"
    else
      waiting_sms = true
      return "Pourriez-vous renvoyer les adresses, avec plus de détail..."
    end
  end

  private

  # création du "service ride"
  def create_request
    create_ride
    @request = Request.create(wait_message: true, service: @ride)
  end

  # création du "service ride", à balancer dans Uber_service
  def create_ride
    @ride = Ride.create(status: "pending")
  end

  # ces methodes seront renvoyées dans RECAST.AI
  def parse_for_start_and_end_address
    split = @message_body.split(";")

    @start_address = split[0]
    if address = Address.create(query: @start_address)
      @start_latitude = address.latitude
      @start_longitude = address.longitude
      @start_address_nice = Geocoder.search("#{@start_latitude},#{@start_longitude }")[0].formatted_address
    end

    @end_address = split[1]
    if address = Address.create(query: @end_address)
      @end_latitude = address.latitude
      @end_longitude = address.longitude
      @end_address_nice = Geocoder.search("#{@end_latitude},#{@end_longitude}")[0].formatted_address
    end
  end

  def parse_for_end_address
    address = Address.create(query: @message_body)
    @end_latitude = address.latitude
    @end_longitude = address.longitude
    @end_address_nice = Geocoder.search("#{@end_latitude},#{@end_longitude}")[0]
  end
end
