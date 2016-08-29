require "recastai"

class MessageParser

  def initialize(message_body, user)
    @message = message_body
    @user = user

    set_request

    @parsed_message = message_parse
    @intention = @parsed_message.intent

    parse_and_answer
  end

  def parse_and_answer

    if @message.downcase == "oui"
      if @request.service
        @request.update(wait_message: false)
        return "C'est parfait. Nous nous occupons de votre commande"
      else
        @request.update(wait_message: false)
        return "Comment puis-je vous aider ?"
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

    if @intention == "ride" # <--- Set un robot
      @answer = ride
    elsif @intention == "information" # <--- Set un robot
      @answer = delivery
      @request.update(wait_message: false)
    elsif @intention == "greetings"# <--- Set un robot
      @answer = "Bonjour#{ @user.first_name} !"
      @request.update(wait_message: false)
    else
      ride
    end

    return @answer
  end

  private

  # liste des services
  def ride
    @request.service = Ride.create(status: "pending") unless @request.service
    @request.save
    @answer = RideConversation.new(@request, @parsed_message).answer
  end

  def delivery
    @request.service = Delivery.create(status: "pending") unless @request.service
    @request.save
    @answer = DeliveryConversation.new(@request, @parsed_message).answer
  end

  def set_request
    # si c'est la première request du user
    new_request if @user.requests.empty?

    # set @request
    @request = @user.requests.last

    # check si la dernière request est close ou si ça fait trop longtemps
    if !@request.wait_message || ((Time.now) - @request.updated_at) / 60 >= 10
      @request.update(wait_message: false)
      @request = new_request
    end
  end

  # création d'un request avec un service
  def new_request
    @request = Request.new(wait_message: true, user: @user)
  end

  def message_parse
    @parsed_message = RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message)
  end
end
