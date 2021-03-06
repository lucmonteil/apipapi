class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    check_addresses
  end

  def answer

    error =     "Je n'ai pas compris votre demande. Pourriez-vous envoyer " \
                "votre demande sous la forme : Je suis au [Adresse de départ, Ville], " \
                "je vais au [Adresse d'arrivée, Ville]"

    if @price
      if @price == "distance_exceeded"
        @answer = "Désolé, la distance entre #{@start_address_nice } " \
                  "et #{@end_address_nice} est supérieure à 100 kilomètres. Veuillez réessayer !"
        @request.update(wait_message: false)
      elsif @price == "no_uber"
        @answer = "Désolé, nous ne trouvons pas de Uber entre #{@start_address_nice } " \
                  "et #{@end_address_nice}."
        @request.update(wait_message: false)
      elsif @request.user.uber_token
        @answer = "Le prix de la course du #{@start_address_nice } " \
                  "au #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                  "dans #{@time} minutes). Envoyez OUI pour commander"
      else
        @answer = "Le prix de la course du #{@start_address_nice } " \
                  "au #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                  "dans #{@time} minutes). Voulez-vous que nous vous appellions maintenant pour vous créer " \
                  "un compte et commander des chauffeurs partout en Europe ?"
      end
    elsif @time
      if @time.class == Fixnum
        @answer = "Une voiture peut venir vous chercher au #{@start_address_nice} " \
                  "dans #{@time} minutes. Pourriez-vous me renvoyer votre adresse " \
                  "d'arrivée pour que je puisse vous proposer un prix ?"
      else
        @answer = "Désolé, la zone autour du #{@start_address_nice} n'est pas encore couverte !"
      end
    elsif @ride.end_address
      @answer = "Votre adresse d'arrivée est #{@start_address_nice}. Je n'ai pas compris votre adresse de départ. Pourriez-vous " \
                "me la renvoyer en précisant la ville ? "
    else
      @answer = error
    end

    return @answer
  end

  private

  # TODO trouver les bonnes clefs entities (indice ce n'est pas :from et :to)
  def check_addresses

    if location = @found_params.entities.detect {|entity| entity.name == "from"} || @ride.start_address
      if @ride.start_address
        address = @ride.start_address
      else
        address = geocode(location.value)
      end

        @ride.start_address = address
        @ride.save

        geo = Geocoder.search("#{address.latitude},#{address.longitude}").first.address_components
        @start_address_nice = geo.first["short_name"] + " " + geo.second["short_name"] + " à " + geo.third["short_name"]


        @time = UberService.new(@ride).time_estimates
        @time = @time / 60 if @time.class == Fixnum

    end

    if location = @found_params.entities.detect {|entity| entity.name == "to"} || @ride.end_address
      if @ride.end_address
        address = @ride.end_address
      else
        address = geocode(location.value)
      end

      @ride.end_address = address
      @ride.save

      geo = Geocoder.search("#{address.latitude},#{address.longitude}").first.address_components
      @end_address_nice = geo.first["short_name"] + " " + geo.second["short_name"] + " à " + geo.third["short_name"]

    end

    if  (location = @found_params.entities.detect {|entity| entity.name == "address"}) && (@ride.end_address || @ride.start_address)

      address = geocode(location.value)
      geo = Geocoder.search("#{address.latitude},#{address.longitude}").first.address_components
      nice_address = geo.first["short_name"] + " " + geo.second["short_name"] + " à " + geo.third["short_name"]


      if @ride.start_address
        @ride.end_address = address
        @end_address_nice = nice_address
      else
        @ride.end_address = address
        @start_address_nice = nice_address
      end

      @ride.save
    end

    if !@ride.end_address.nil? && !@ride.start_address.nil?
      @price = UberService.new(@ride).price_estimates
    end
  end

  # on utilise pas les lat et lng de Recast, ça fait trop de conditions
  def geocode(search)

    geo = Geocoder.search(search + ", France").first.address_components
    searched_address = geo.first["short_name"] + " " + geo.second["short_name"] + " " + geo.third["short_name"]

    if @ride.start_address || @ride.end_address
      p_address = @ride.start_address if @ride.start_address
      p_address = @ride.end_address if @ride.end_address

      p_lat = p_address.latitude
      p_lng = p_address.longitude

      found_addresses = Geocoder.search(searched_address)

      distances = []

      found_addresses.each do |address|

        lat = address.geometry["location"]["lat"]
        lng = address.geometry["location"]["lng"]

        distance = Geocoder::Calculations.distance_between("#{p_lat},#{p_lng}", "#{lat},#{lng}")

        item = [address, distance]

        distances << item
      end

      distances.sort_by! { |address| address[1] }

      closest_address_raw_name = distances.first.first.formatted_address

      address = Address.new(query: closest_address_raw_name)
      address.validate # triggers geocoder
      address.save
      return address
    else
      address = Address.new(query: searched_address)
      address.validate # triggers geocoder
      address.save
      return address
    end
  end
end
