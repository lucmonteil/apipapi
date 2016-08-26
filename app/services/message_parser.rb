class MessageParser

  def initialize(message_body, user)
    @message_body = message_body
    @user = user
  end

  def point_to_service

    # check si c'est la première request du user
    if @user.requests.empty?
      @request = create_request
    end

    # check si la dernière request est close
    unless @user.requests.last.wait_message
      @request = create_request
    end

    @request = @user.requests.last

    if message_intention == "order a ride" # <--- TODO trouver le bon nom

      @request.service = create_ride if @request.wait_message

      @reply_message_body = RideConversation.new(@request, @parsing).conversation_ride # <---- parsing va remplacer @message_body

    else
      @reply_message_body = "Notre service se limite à vous commander un Uber..."
    end

    @request.wait_message = false
    @request.save

    return @reply_message_body
  end

  private


  def message_intention
    # ici même pas de split, on prend toute la string
    @parsing = RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message_body)
    @intention = @parsing.intent
  end

  # création d'un request avec un service
  def create_request
    @request = Request.create(wait_message: true, user: @user)
  end

  def create_ride
    @ride = Ride.create(status: "pending")
  end
end
