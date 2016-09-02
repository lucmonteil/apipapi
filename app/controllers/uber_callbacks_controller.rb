class UberCallbacksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    # TODO: check signature Uber

    # On retrouve la ride concerné par le post du webhook uber

    @ride = Ride.find_by(uber_request_id: params["meta"]["resource_id"])

    if @ride && @ride.user
    # On va aller chercher les nouveaux détails de la ride maintenant (sinon ==> on lance donc un get avec href_resource pour obtenir les infos de la ride)
      api_object = UberService.new(@ride)
      @response = api_object.request_details

      # On determine a quel user renvoyer le texto en renvoyant son numero de telephone
      @phone_number = @ride.user.phone_number

      test_and_reply
    end

    head :ok
  end

  private

  def test_and_reply
    # envoie du message avec Twilio
    if @response.status != "processing"
      if @response.status == "accepted"
        @message_body = "#{@response.driver.name} arrive dans #{@response.eta} minutes dans une #{@response.vehicle.make}"
        unless @message_body == @ride.user.messages.last.body
          create_message
          reply
        end
      elsif @response.status == "rider_canceled"
        unless @message_body == @ride.user.messages.last.body
          create_message
          reply
        end
        @message_body = "Votre Uber est annulé. Merci de votre confiance"
      end
    else
      p "================================= IL EST PROCESSING DONC PAS DE TEXTO ================================="
    end
  end

  def reply
    client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
    apipapi_phone_number = ENV['TWILIO_NUMBER']
    sms = client.messages.create(
          from: apipapi_phone_number,
          to: @phone_number,
          body: @message_body
        )
  end

  def create_message
    Message.create(body: @message_body, user: @ride.user, sender: false)
  end
end
