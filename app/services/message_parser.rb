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
        "nous proposons des courses UBER. Demandez une estimation en m'envoyant " \
        "votre adresse de départ (avec la ville) et votre adresse d'arrivée"

    if @intention == "say-hi"
      sentences = @parsed_message.sentences
      if sentence = sentences.detect { |sentence| sentence.entities.detect {|entity| entity.name == "person" } }
        entities = sentence.entities
        @first_name = entities.detect { |entity| entity.name == "person" }.raw
        @user.first_name = @first_name
        @user.save
        return "Bonjour #{@first_name}! " \
               "Nous proposons des courses UBER. Demandez une estimation en m'envoyant " \
               "votre adresse de départ (avec la ville) et votre adresse d'arrivée"
      end
      return "Bonjour je suis votre assistant Uber ! " \
             "Demandez une estimation de course en m'envoyant " \
             "votre adresse de départ (avec la ville) et votre adresse d'arrivée"
    elsif @intention == "reverse-address"
      return reverse_addresses
    elsif @intention == "get-a-cab" || @intention == "complementary-address"
      return ride_conversation
    elsif @intention == "information"
      return "Nous proposons des courses UBER. Demandez une estimation en m'envoyant " \
             "votre adresse de départ (avec la ville) et votre adresse d'arrivée"
    elsif @intention == "accept"
      if (@ride = @request.service) && @ride.start_address && @ride.end_address
        @request.update(wait_message: false)
        if @request.user.uber_token

          # APPEL DU UBER
          uber_request
          # il faut gérer les erreurs au cas ou il y a un pb lors de la commande
          if @response == "Surge pricing"
            return "Veuillez m'excuser#{@first_name ? ' ' + @first_name : ""}, la majoration tarifaire du service Uber est trop élevée en ce moment, veuillez réessayer dans quelques minutes. Merci"
          elsif @response.status
            return "Merci#{@first_name ? ' ' + @first_name : ""}. Nous vous confirmons l'arrivée de votre "\
                   "chauffeur dans les 3 minutes."
          else
            return "Veuillez m'excuser#{@first_name ? ' ' + @first_name : ""}. Je n'ai pas réussi à vous trouver une voiture. " \
                   "Refaites une demande d'estimation en attendant 5 minutes et je ferai de mon mieux"
          end
        else
          return "Dring, Dring"
        end
      else
        return "Je serai ravi de vous aider. "\
               "Demandez une estimation de course en m'envoyant " \
               "votre adresse de départ (avec la ville) et votre adresse d'arrivée"
      end
    elsif @intention == "cancel"
      if @request.service
        @request.update(wait_message: false)
        return "Votre commande a été annulée. Renvoyer une demande d'estimation quand vous "\
               "voulez : je reste à votre service"
      else
        return "Il n'y a pas de demande en cours. Je me suis peut-etre emmelé les pinceaux "\
               "nous proposons des courses UBER. Demandez une estimation en m'envoyant " \
               "votre adresse de départ (avec la ville) et votre adresse d'arrivée"
      end
    else
      return error
    end
  end

  private

  # liste des services
  def ride_conversation
    @request.service = Ride.create(status: "pending") unless @request.service
    @request.save
    @answer = RideConversation.new(@request, @parsed_message).answer
  end

  def uber_request
    api_uber_object = UberService.new(@request.service)

    # Passe la commande de Uber et reçoit la réponse
    @response = api_uber_object.ride_request

    p @response

    unless @response == "Surge pricing"
      # stocker la request id du ride chez uber pour pouvoir suivre son status
      @request.service.uber_request_id = @response.request_id
      @request.service.save
    end

    return @response
  end

  # TODO: possibilité d'annuler
  # def uber_cancellation
  # end

  def set_request
    # check si c'est la première request du user
    if @user.requests.empty?
      @request = create_request
    else
      @request = @user.requests.last
    end

    # check si la dernière request est close ou si ça fait trop longtemps (300 secondes = 2.5 minutes)
    if !@request.wait_message || ((Time.now) - @request.updated_at)  >= 150
      @request.update(wait_message: false)
      @request = create_request
    end
  end

  def reverse_addresses
    if @ride = @user.requests.last.service
      if @ride.start_address && @ride.end_address

        from = @ride.start_address
        to = @ride.end_address
        @ride.end_address = from
        @ride.start_address = to

        @ride.save
        return "C'est réparé. " + ride_conversation
      elsif @ride.start_address

        adress = @ride.start_address
        @ride.end_address = adress
        @ride.start_address = nil

        @ride.save
        return "Ça devrait être bon maintenant : " + ride_conversation
      elsif @ride.start_address

        adress = @ride.end_address
        @ride.start_address = adress
        @ride.end_address = nil

        @ride.save
        return "Ok. " + @ride.start_address
      else
        return "Refaites une estimation de course avec vos adresses précises de départ et d'arrivée"
      end
    else
      return "Refaites une estimation de course avec vos adresses précises de départ et d'arrivée"
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
