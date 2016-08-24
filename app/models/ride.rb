class Ride < ApplicationRecord
  has_one :request, as: :service

  has_one :start_address, class_name: 'Address', foreign_key: :start_address_id
  has_one :end_address, class_name: 'Address', foreign_key: :end_address_id

  def user
    request.user
  end
end
