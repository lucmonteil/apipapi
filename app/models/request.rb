class Request < ApplicationRecord
  belongs_to :service, polymorphic: true
  belongs_to :user
end
