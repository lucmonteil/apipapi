require "recastai"

class MessageParser

  def initialize(message_body, user)
    @message = message_body
    @user = user
  end

  def request_handler
    # check si c'est la première request du user
    if @user.requests.empty?
      new_request
      return parse_point_to_service_and_answer
    end

    @request = @user.requests.last

    # on regarde le temps entre la dernière requête et maintenant
    time_out = (((Time.now) - @request.updated_at)/60 >= 10)

    # check si la dernière request est close ou si ça fait trop longtemps
    if !@request.wait_message || time_out
      @request.update(wait_message: false)
      @request = new_request
    end

    return parse_point_to_service_and_answer
  end

  def parse_point_to_service_and_answer

    if @message.downcase == "oui"
      if @request.service
        @request.update(wait_message: false)
        return "C'est parfait. Nous nous occupons de votre commande"
      else
        @request.update(wait_message: false)
        return "Cette attitude positive n'est pas pour me déplaire. "\
               "Comment puis-je vous aider ?"
      end
    end

    if @message.downcase == "annuler"
      if @request.service
        @request.update(wait_message: false)
        return "Votre commande a été annulée. Renvoyer une demande quand vous "\
               "voulez : je reste à votre service"
      else
        @request.update(wait_message: false)
        return "Je me suis emmelé les pinceaux. Pourriez-vous me dire "\
               "comment je peux vous venir en aide ?"
      end
    end
    #parsing du message
    @parsed_message = message_parse
    @intention = @parsed_message.intent

    if @intention == "ride" # <--- TODO trouver le bon nom
      @reply = ride
    elsif @intention == "delivery" # <--- Fake service pour exemple
      @reply = delivery
    elsif @intention == "joke"
      @reply = "J'espère que c'est une blague..."
    else
      #réponse par défaut avant de bien comprendre les intentions dans recastAI
      ride
    end

    return @reply
  end

  # liste des services
  def ride
    @request.service = Ride.create(status: "pending") unless @request.service
    @request.save
    @reply = RideConversation.new(@request, @parsed_message).answer
  end

  def delivery
    @request.service = Delivery.create(status: "pending") unless @request.service
    @request.save
    @reply = DeliveryConversation.new(@request, @parsed_message).answer
  end

  private

  def message_parse
    RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message)
  end

  # création d'un request avec un service
  def new_request
    @request = Request.new(wait_message: true, user: @user)
  end
end
