class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    set_variables
  end

  def answer

    error =     "Je n'ai pas compris votre demande. Pourriez-vous envoyer " \
                "votre demande sous la forme : Je suis au [Addresse de départ], " \
                "je vais au [Addresse d'arrivée]"
    if @price
      if @price == "distance_exceeded"
        @answer = "Désolé, la distance entre #{@start_address_nice } " \
                "à #{@end_address_nice} est supérieure à 100 kilomètres. Veuillez réessayer !"
      elsif @price == "no_uber"
        @answer = "Désolé, nous ne trouvons pas de Uber entre #{@start_address_nice } " \
                "et #{@end_address_nice}. Veuillez réessayer !"
      else
        @answer = "Le prix de la course de #{@start_address_nice } " \
                "à #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                "dans #{@time} minutes). Envoyez OUI pour commander"
      end
      @request.update(wait_message: false)
    elsif @time
      if @time.class == Integer
        @answer = "Une voiture peut venir vous chercher au #{@start_address_nice} " \
                  "dans #{@time} minutes. Pourriez-vous me renvoyer votre adresse " \
                  "d'arrivée pour que je puisse vous proposer un prix ? Envoyer ANNULER " \
                  "si j'ai mal compris."
      else
        @answer = "Désolé, la zone autour de #{@start_address_nice} n'est pas encore couverte !"
      end
    elsif @end_address
      @answer = "Je n'ai pas compris votre adresse de départ. Pourriez-vous " \
                "me la renvoyer ? "
    else
      @answer = error
    end

    return @answer
  end

  private

  # TODO trouver les bonnes clefs entities (indice ce n'est pas :from et :to)
  def set_variables

    if address = @found_params.entities.detect {|entity| entity.name == "address"} || @ride.start_address
      if @ride.start_address.nil?
        geocode(address.value, "start") if address
        @ride.start_address = @start_address
        @ride.save
      else
        @start_address = @ride.start_address
      end
      @time = UberService.new(@ride).time_estimates
      @time = @time / 60 if @time.class == Fixnum
      @start_address_nice = Geocoder.search("#{@start_address.latitude},#{@start_address.longitude}")[0].formatted_address
    end

    if destination = @found_params.entities.detect {|entity| entity.name == "destination"} || @ride.end_address
      if @ride.end_address.nil?
        geocode(destination.value, "end") if destination
        @ride.end_address = @end_address
        @ride.save
      else
        @end_address = @ride.end_address
      end
      @end_address_nice = Geocoder.search("#{@end_address.latitude},#{@end_address.longitude}")[0].formatted_address
    end

    unless @ride.end_address.nil? || @ride.start_address.nil?
      @price = UberService.new(@ride).price_estimates
    end
  end

  # on utilise pas les lat et lng de Recast, ça fait trop de conditions
  def geocode(searched_address, prefix)
    address = Address.new(query: searched_address)
    address.validate # triggers geocoder
    address.save
    instance_variable_set("@#{prefix}_address", address)
  end
end
