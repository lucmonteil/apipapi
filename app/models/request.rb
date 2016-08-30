class Request < ApplicationRecord
  belongs_to :service, polymorphic: true, optional: true
  belongs_to :user, optional: true
end
