class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    set_variables
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

  # TODO trouver les bonnes clefs (indice ce n'est pas :from et :to)
  def set_variables
    address = @found_params.entities.detect {|e| e.name == "address"}
    geocode(address.value, "start") if address
    destination = @found_params.entities.detect {|e| e.name == "destination"}
    geocode(destination.value, "end") if destination
  end

  # on utilise pas les lat et lng de Recast, ça fait trop de conditions
  def geocode(searched_address, prefix)
    address = Address.new(query: searched_address)
    address.validate # triggers geocoder
    if address.save
      lat = instance_variable_set("@#{prefix}_latitude", address.latitude)
      lng = instance_variable_set("@#{prefix}_longitude", address.longitude)
      instance_variable_set("@#{prefix}_address_nice", Geocoder.search("#{lat},#{lng}")[0].formatted_address)
      instance_variable_set("@#{prefix}_address", address)
    end
  end
end
