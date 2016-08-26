class RideConversation

  def initialize(request, parsing)
    @request = request
    @ride = @request.service
    @parsing = parsing
    @message_body = @parsing.sentences[0].source
    # @found_start_address = parsed_message[:start_address] || nil
    # @found_end_address = parsed_message[:end_address] || nil
    # @approval = parsed_message[:approval] || nil
  end

  def conversation_ride

    parsing # TODO

    # geocode(@found_start_address, "start")
    # geocode(@found_end_address, "end")


    @ride.save if @ride.end_address = @end_address
    @ride.save if @ride.start_address = @start_address

    @price = UberService.new(@ride).price_estimates
    @time = UberService.new(@ride).time_estimates

    @answer_body_message = "Le prix de la course de #{@ride.start_address.query} à #{@ride.end_address.query} est de #{@price} (il arrive dans #{@time/60} minutes)"

    return @answer_body_message
  end

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

  def parse_for_start_and_end_address
    # ici la pire AI du monde !
    split = @message_body.split(";")
    @found_start_address = split[0]
    @found_end_address = split[1]
  end
end
