class CreateRides < ActiveRecord::Migration[5.0]
  def change
    create_table :rides do |t|
      t.references :user, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
