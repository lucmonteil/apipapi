class Address < ApplicationRecord
  geocoded_by :query

  validates :latitude, presence: true
  validates :longitude, presence: true

  after_validation :geocode, if: :query_changed?
end
