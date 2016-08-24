class MessageParser

  def initialize(message_body)
    @message_body = message_body
  end

  def parse_for_address
    split = @message_body.split(";")

    start_address = Address.create(query: split[0])
    end_address = Address.create(query: split[1])
    return {
        start_latitude: start_address.latitude,
        start_longitude: start_address.longitude,
        end_latitude: end_address.latitude,
        end_longitude: end_address.longitude,
    }
  end

end
