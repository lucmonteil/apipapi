class AddColumnsToRides < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :start_address_id, :integer
    add_column :rides, :end_address_id, :integer
  end
end
