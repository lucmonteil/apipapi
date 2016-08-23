class MessageParser

  def initialize(message_body)
    @message_body = message_body
  end

  def parse_for_address
    split = @message_body.split(";")
    start_address = split[0]
    end_address = split[1]
    return ride = {
      start: start_address,
      end: end_address
    }
  end

end
