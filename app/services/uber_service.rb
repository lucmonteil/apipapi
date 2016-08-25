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
    @client.price_estimations(
      start_latitude: @ride.start_address.latitude,
      start_longitude: @ride.start_address.longitude,
      end_latitude: @ride.end_address.latitude,
      end_longitude: @ride.end_address.longitude
      ).second[:estimate]
  end

  def time_estimates
    @client.time_estimations(
      start_latitude: @ride.start_address.latitude,
      start_longitude: @ride.start_address.longitude
      ).second[:estimate]
  end
end
