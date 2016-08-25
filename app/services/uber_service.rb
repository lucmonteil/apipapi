class UberService

  def initialize(ride)
    @ride = ride
  end

  def estimate_price
    @price = "23 euros"
    return "Le prix de la course de #{@ride.start_address.query} à #{@ride.end_address.query} est de #{@price}"
  end
end
