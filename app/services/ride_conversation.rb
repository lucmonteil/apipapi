class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    set_variables
  end

  def conversation_ride

    @ride.save if @ride.end_address = @end_address
    @ride.save if @ride.start_address = @start_address

    @price = UberService.new(@ride).price_estimates
    @time = UberService.new(@ride).time_estimates

    if @start_address && @end_address
      @answer = "Le prix de la course de #{@start_address_nice } " \
                "à #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                "dans #{@time/60} minutes). Envoyez OUI pour commander"
    elsif @start_address
      @answer = "Une voiture peut venir vous chercher au #{@start_address_nice} " \
                "dans #{@time/60} minutes). Pourriez-vous me renvoyer votre adresse " \
                "d'arrivée pour que je puisse vous proposer un prix ?"
    elsif @end_address
      @answer = "Je n'ai pas compris votre adresse de départ. Pourriez-vous " \
                "me la renvoyer ? "
    elsif
      @answer = "Je n'ai pas compris... pourriez-vous renvoyer " \
                "vos addresses de départ et d'arrivée ? "
    else

    end

    return @answer
  end

  private

  # TODO trouver les bonnes clefs (indice ce n'est pas :from et :to)
  def set_variables
    geocode(@found_params[:from], "start") if @found_params[:from]
    geocode(@found_params[:to], "end") if @found_params[:to]
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
