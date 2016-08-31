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

    error = "Je n'ai pas compris votre demande. Pour le moment " \
            "nous proposons des courses UBER. Essayez en nous donnant " \
            "votre adresse de départ et votre adresse d'arrivée."

    if @intention == "accept"
      if @request.service
        if @request.service.start_address && @request.service.end_address
          @request.update(wait_message: false)
          # APPEL DU UBER
          uber_request
          # il faut gérer les erreurs au cas ou il y a un pb lors de la commande
          return "C'est parfait. Nous vous confirmons l'arrivée de votre chauffeur dans les plus brefs délais. #{@response.status}"
        end
      else
        return "Comment puis-je vous aider ?"
      end
    elsif @intention == "cancel"
      if @request.service
        @request.update(wait_message: false)
        return "Votre commande a été annulée. Renvoyer une demande quand vous "\
               "voulez : je reste à votre service"
      else
        return "Je me suis emmelé les pinceaux. "\
               "Comment puis-je vous venir en aide ?"
      end
    end

    if @intention == "get-a-cab" || @intention == "complementary-address"
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

    # Passe la commande de Uber et reçoit la réponse
    @response = api_uber_object.ride_request

    # stocker la request id du ride chez uber pour pouvoir suivre son status
    @request.service.uber_request_id = @response.request_id
    @request.service.save
  end

  def set_request
    # check si c'est la première request du user
    if @user.requests.empty?
      @request = create_request
    else
      @request = @user.requests.last
    end

    # check si la dernière request est close ou si ça fait trop longtemps (600 secondes = 10 minutes)
    if !@request.wait_message || ((Time.now) - @request.updated_at)  >= 600
      @request.update(wait_message: false)
      @request = create_request
    end
  end

  # création d'un request avec un service
  def create_request
    @request = Request.new(wait_message: true)
    @request.user = @user
    @request.save
    @request
  end

  def message_parse
    @parsed_message = RecastAI::Client.new(ENV["RECAST_TOKEN"], "fr").text_request(@message)
  end
end


# #test de uber request
# parameters = {
#      start_latitude: 48.864667,
#      start_longitude: 2.378838,
#      end_latitude: 48.852115,
#      end_longitude: 2.268011
#    }

# ride

