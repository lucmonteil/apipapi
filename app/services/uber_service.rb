class UberService

  def initialize(ride)
    @ride = ride

    #instance de client uber (🤔sans bearer token)
    params = {
      sandbox: (Rails.env == "developement"),
      #tokens d'environnement
      server_token: ENV["UBER_SERVER_TOKEN"],
      client_id: ENV["UBER_CLIENT_ID"],
      client_secret: ENV["UBER_CLIENT_SECRET"]
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
end
