class Address < ApplicationRecord
  geocoded_by :query
  after_validation :geocode, if: :query_changed?
end
