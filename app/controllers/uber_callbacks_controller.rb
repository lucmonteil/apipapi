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

    reply

    head :ok
  end

  private

  def reply
    # envoit du message avec Twilio
    if @response.status != "processing"
      if @response.status == "accepted"
        client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
        apipapi_phone_number = ENV['TWILIO_NUMBER']
        sms = client.messages.create(
              from: apipapi_phone_number,
              to: @phone_number,
              body: "Votre commande Uber est #{@response.status}, #{@response.driver} arrivera dans #{@response.eta} minutes. Soyez prêt!"
            )
      elsif @response.status == "rider_canceled"
        client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
        apipapi_phone_number = ENV['TWILIO_NUMBER']
        sms = client.messages.create(
              from: apipapi_phone_number,
              to: @phone_number,
              body: "Nous vous confirmons l'annulation de votre Uber. A très vite sur Happy papi ;)"
            )
      end
    else
      p "=================IL EST PROCESSING DONC PAS DE TEXTO ================================="
    end
  end

  def create_message
    if @response.status != "processing"
      if @response.status == "accepted"
        Message.create(body: "Votre commande Uber est #{@response.status}, #{@response.driver} arrivera dans #{@response.eta} minutes. Soyez prêt!")
      elsif @response.status == "rider_canceled"
        Message.create(body: "Nous vous confirmons l'annulation de votre Uber. A très vite sur Happy papi ;)")
      end
    else
      p "=================IL EST PROCESSING DONC PAS DE TEXTO ================================="
    end
  end
end
