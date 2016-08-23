class MessageParser

  def initialize(message_body)
    @message_body = message_body
  end

  def parse
    message_hash = {}
    if @message_body = 'ok'
      message_hash[validate] = true
    elsif @message_body = 'nok'
      message_hash[validate] = false
    else
      message_hash =>...
    end

  end

end
