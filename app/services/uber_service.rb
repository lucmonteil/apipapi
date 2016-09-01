class UberService

  def initialize(ride)
    @ride = ride

    # On prend le token du poto qui vuet commander
    @bearer_token = ride.user.uber_token

    # On se limite à commander des uberX pour l instant
    @product_id = "5b451799-a7c3-480e-8720-891f2b51abb4"

    #instance de client uber (🤔sans bearer token)

    #tokens d'environnement
    oauth_params = {
      sandbox: false,
      server_token: ENV["UBER_SERVER_TOKEN"],
      client_id: ENV["UBER_CLIENT_ID"],
      client_secret: ENV["UBER_CLIENT_SECRET"],
      bearer_token: @bearer_token,
    }

    @oauth_client = Uber::Client.new(oauth_params)

    params = {
      sandbox: false,
      server_token: ENV["UBER_SERVER_TOKEN"],
      client_id: ENV["UBER_CLIENT_ID"],
      client_secret: ENV["UBER_CLIENT_SECRET"],
    }

    # On va chercher le request_id pour updater son status après le get qui vient du webhook (voir create du uber_callbacks controller)
    @request_id = ride.uber_request_id

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
    rescue StandardError => error
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
    # if @request_id
    #   @oauth_client.trip_cancel @request_id
    # end

    response = @oauth_client.trip_request(
      product_id: @product_id,
      start_latitude: @ride.start_address.latitude,
      start_longitude: @ride.start_address.longitude,
      end_latitude: @ride.end_address.latitude,
      end_longitude: @ride.end_address.longitude
    )
  end

  def request_details
    response = @oauth_client.trip_details @request_id
  end

  # TODO: Annulation volontaire
  # def cancel_request
  #   response = @oauth_client.trip_cancel @request_id
  # end
end
