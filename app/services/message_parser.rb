require "recastai"

class MessageParser

  def initialize(message_body, user)
    @message = message_body
    @user = user

    set_request

    @parsed_message = message_parse
    @intention = @parsed_message.intent
  end

  def reply

    error = "Je n'ai pas compris votre demande. Pour me moment " \
            "nous proposons des courses UBER. Essayez en nous donnant " \
            "votre adresse de départ et votre adresse d'arrivée."
    if @intention == "accept"
      if @request.service
        if @request.service.start_address && @request.service.end_address
          @request.update(wait_message: false)
          uber_request
          # il faut gérer les erreurs au cas ou il y a un pb lors de la commande
          return "C'est parfait. Nous nous occupons de votre commande. ( #{@response} )"
        end
      else
        @request.update(wait_message: false)
        return "Comment puis-je vous aider ?"
      end
    elsif @intention == "cancel"
      if @request.service
        @request.update(wait_message: false)
        return "Votre commande a été annulée. Renvoyer une demande quand vous "\
               "voulez : je reste à votre service"
      else
        @request.update(wait_message: false)
        return "Je me suis emmelé les pinceaux. "\
               "Comment puis-je vous venir en aide ?"
      end
    end

    if @intention == "get-a-cab"
      return ride
    elsif @intention == "information"
      return "Nous proposons des courses UBER. Essayez en nous donnant " \
              "votre adresse de départ et votre adresse d'arrivée."
    elsif @intention == "say-hi"
      sentences = @parsed_message.sentences
      if sentence = sentences.detect { |sentence| sentence.entities.detect {|entity| entity.name == "firstname" } }
        entities = sentence.entities
        @first_name = entities.detect { |entity| entity.name == "firstname" }.raw
        @user.first_name = @first_name
        @user.save
      end
      @first_name = "" if @user.first_name.downcase == "unknown"
      return "Bonjour #{@first_name}! Comment puis-je vous aider ?"
    else
      return error
    end
  end

  private

  # liste des services
  def ride
    @request.service = Ride.create(status: "pending") unless @request.service
    @request.save
    @answer = RideConversation.new(@request, @parsed_message).answer
  end

  def uber_request
    api_uber_object = UberService.new(@request.service)
    @response = api_uber_object.ride_request
    # Commander puis stocker la request id du ride chez uber pour pouvoir suivre son status
  end

  def set_request
    # si c'est la première request du user
    @request = new_request if @user.requests.empty?

    # set @request
    @request = @user.requests.last

    # check si la dernière request est close ou si ça fait trop longtemps (600 secondes = 10 minutes)
    if !@request.wait_message || ((Time.now) - @request.updated_at)  >= 600
      @request.update(wait_message: false)
      @request = new_request
    end
  end

  # création d'un request avec un service
  def new_request
    @request = Request.new(wait_message: true)
    @request.user = @user
    @request.save
    @request
  end

  def message_parse
    @parsed_message = RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message)
  end
end
