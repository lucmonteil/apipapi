class Ride < ApplicationRecord
  has_one :request, as: :service

  belongs_to :start_address, class_name: 'Address', foreign_key: :start_address_id, required: false
  belongs_to :end_address, class_name: 'Address', foreign_key: :end_address_id, required: false

  def user
    request.user
  end
end
