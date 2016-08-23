class MessageParser

  def initialize(message_body)
    @message_body = message_body
  end

  def parse_for_address
    split = @message_body.split(";")

    start_address = Address.create(query: split[0])
    end_address = Address.create(query: split[1])
    return {
      start_address: start_address,
      start_address_reverse: Geocoder.search("#{start_address.latitude},#{start_address.longitude}")[0],
      start_latitude: start_address.latitude,
      start_longitude: start_address.longitude,
      end_address: end_address,
      end_address_reverse: Geocoder.search("#{end_address.latitude},#{end_address.longitude}")[0],
      end_latitude: end_address.latitude,
      end_longitude: end_address.longitude,
    }
  end
end
