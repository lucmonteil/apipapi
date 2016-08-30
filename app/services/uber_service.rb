class UberService

  def initialize(ride)
    @ride = ride

    # On prend le token du poto qui vuet commander
    @bearer_token = ride.user.uber_token

    # On se limite à commander des uberX pour l instant
    @product_id = "5b451799-a7c3-480e-8720-891f2b51abb4"

    #instance de client uber (🤔sans bearer token)
    params = {
      sandbox: (Rails.env == "developement"),
      #tokens d'environnement
      server_token: ENV["UBER_SERVER_TOKEN"],
      client_id: ENV["UBER_CLIENT_ID"],
      client_secret: ENV["UBER_CLIENT_SECRET"],
      bearer_token: @bearer_token,
    }

    @client = Uber::Client.new(params)
  end

  def price_estimates
    # TODO gérer les erreurs de type :
    # 'Distance between two points exceeds 100 miles'
    #
    begin
      estimation = @client.price_estimations(
        start_latitude: @ride.start_address.latitude,
        start_longitude: @ride.start_address.longitude,
        end_latitude: @ride.end_address.latitude,
        end_longitude: @ride.end_address.longitude
        )
      car = estimation.detect {|e| e.display_name == "uberX"}
      if car
        car[:estimate]
      else
        return "no_uber"
      end
    rescue Uber::Error::UnprocessableEntity => error
      error.message
    end
  end

  def time_estimates
    car = @client.time_estimations(
    start_latitude: @ride.start_address.latitude,
    start_longitude: @ride.start_address.longitude
    ).detect {|e| e.display_name == "uberX"}
    if car
      car[:estimate]
    else
      return "no_uber"
    end
  end

  def ride_request
    response = @client.trip_request(
      product_id: @product_id,
      start_latitude: @start_latitude,
      start_longitude: @start_longitude,
      end_latitude: @end_latitude,
      end_longitude: @end_longitude
      )
  end
end
