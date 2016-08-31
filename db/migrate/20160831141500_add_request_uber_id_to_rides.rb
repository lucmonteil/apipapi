class AddRequestUberIdToRides < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :uber_request_id, :string
  end
end
