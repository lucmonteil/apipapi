class CreateAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :addresses do |t|
      t.string :query
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
