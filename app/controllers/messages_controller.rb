class MessagesController < ApplicationController

 #vérifier le skip_before_filter (skipp la vérification de l'auth token)
 skip_before_action :verify_authenticity_token

 #skip l'auth token pour Devise
 skip_before_action :authenticate_user!, :only => "reply"

  def reply
    message_body = params["Body"]
    from_number = params["From"]
    @user = User.find_by_phone_number(from_number)
    Message.create(body: message_body, user: @user)
    boot_twilio
    sms = @client.messages.create(
      from: ENV['TWILIO_NUMBER'],
      to: from_number,
      body: "Hello world mothafoka!"
    )

  end

  private

  def boot_twilio
    @client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
  end
end
