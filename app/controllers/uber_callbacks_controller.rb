class UberCallbacksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    # TODO: check signature Uber

    # On retrouve la ride concerné par le post du webhook uber
    @ride = Ride.find_by(uber_request_id: params["meta"]["resource_id"])

    # si ya eu un changement de statut, on va vouloir envoyer un texto avec le nouveau statut

    # on lance donc un get avec href_resource pour obtenir les infos de la ride
    api_object = UberService.new(@ride)
    response = api_object.request_details
    p response

    render status: 200
  end
end
