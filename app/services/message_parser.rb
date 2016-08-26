class MessageParser

  def initialize(message_body, user)
    @message = message_body
    @user = user
  end

  def request_handler
    # check si c'est la première request du user
    if @user.requests.empty?
      @request = create_request
    end

    # on regarde le temps entre la dernière requête et maintenant
    # le 7200 c'est pour ajouter 2h pour le décalage horaire, TODO peut mieux faire
    time_out = (((Time.now + 7200) - @user.requests.last.updated_at)/60 >= 10)

    # check si la dernière request est close ou si ça fait trop longtemps
    if !@user.requests.last.wait_message || time_out
      @user.requests.last.update(wait_message: false)
      @request = create_request
    end

    @request = @user.requests.last

    return parse_point_to_service_and_reply
  end

  def parse_point_to_service_and_answer

    if @message.downcase == "oui"
      @request.wait_message = false
      @request.save
      return "C'est parfait. Nous nous occupons de votre commande"
    end
    #parsing du message
    @parsed_message = message_parse
    @intention = @parsing.intent

    if @intention == "ride" # <--- TODO trouver le bon nom
      ride
    elsif @intention == "delivery" # <--- Fake service pour exemple
      delivery
    elsif @intention == "joke"
      @reply = "J'espère que c'est une blague..."
    else
      #réponse par défaut avant de bien comprendre recastAI
      ride
    end

    return @reply
  end

  # liste des services
  def ride
    @request.service = Ride.create(status: "pending") if @request.wait_message
    @reply = RideConversation.new(@request, @parsed_message)
  end

  def delivery
    @request.service = Delivery.create(status: "pending") if @request.wait_message
    @reply = Deliveryonversation.new(@request, @parsed_message)
  end

  private

  def message_parse
    # ici même pas de split, on prend toute la string
    RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message)
  end

  # création d'un request avec un service
  def create_request
    @request = Request.create(wait_message: true, user: @user)
  end
end
