class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    set_variables

    @start_address_nice = Geocoder.search("#{@end_address.latitude},#{@end_address.longitude}")[0].formatted_address
    @start_address_nice = Geocoder.search("#{@start_address.latitude},#{@start_address.longitude}")[0].formatted_address
  end

  def answer

    error = "[ error/ride_conversation in answer ]"


    @ride.save if @ride.end_address = @end_address


    if @ride.start_address = @start_address
      @ride.save
      @time = UberService.new(@ride).time_estimates / 60
    end

    if @start_address && @end_address
      @price = UberService.new(@ride).price_estimates
      @answer = "Le prix de la course de #{@start_address_nice } " \
                "à #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                "dans #{@time} minutes). Envoyez OUI pour commander"
    elsif @start_address
      @answer = "Une voiture peut venir vous chercher au #{@start_address_nice} " \
                "dans #{@time} minutes. Pourriez-vous me renvoyer votre adresse " \
                "d'arrivée pour que je puisse vous proposer un prix ? Envoyer ANNULER " \
                "si j'ai mal compris."
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
    if @ride.start_address.nil?
      address = @found_params.entities.detect {|entitie| entitie.name == "address"}
      geocode(address.value, "start") if address
    else
      @start_address = @ride.start_address
    end
    if @ride.end_address.nil?
      destination = @found_params.entities.detect {|entitie| entitie.name == "destination"}
      geocode(destination.value, "end") if destination
    else
      @end_address = @ride.end_address
    end
  end

  # on utilise pas les lat et lng de Recast, ça fait trop de conditions
  def geocode(searched_address, prefix)
    address = Address.new(query: searched_address)
    address.validate # triggers geocoder
    if address.save
      instance_variable_set("@#{prefix}_latitude", address.latitude)
      instance_variable_set("@#{prefix}_longitude", address.longitude)
      instance_variable_set("@#{prefix}_address", address)
    end
  end
end
