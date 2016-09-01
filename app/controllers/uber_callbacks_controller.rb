class UberCallbacksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    # TODO: check signature Uber

    # On retrouve la ride concerné par le post du webhook uber

    @ride = Ride.find_by(uber_request_id: params["meta"]["resource_id"])

    # On va aller chercher les nouveaux détails de la ride maintenant (sinon ==> on lance donc un get avec href_resource pour obtenir les infos de la ride)
    api_object = UberService.new(@ride)
    @response = api_object.request_details

    p @response
    p "=========================YOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO====================================="
    # On veut les envoyer le nouveau statut par texto

    # On determine a quel user renvoyer le texto en renvoyant son numero de telephone
    @phone_number = @ride.user.phone_number

    create_message

    head :ok
  end

  private

  def reply
    # envoit du message avec Twilio
    client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
    apipapi_phone_number = ENV['TWILIO_NUMBER']
    sms = client.messages.create(
            from: apipapi_phone_number,
            to: @phone_number,
            body: "Your Uber is #{@response.status}, #{@response.driver} is arriving in #{@response.eta} min !"
          )
  end

  def create_message
    Message.create(body: "Your Uber is #{@response.status}, #{@response.driver} is arriving in #{@response.eta} min !", user: @ride.user, sender: false)
  end
end
