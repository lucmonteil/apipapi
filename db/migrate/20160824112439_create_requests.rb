class CreateRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :requests do |t|
      t.references :user, foreign_key: true
      t.references :service, polymorphic: true, index: true
      t.boolean :wait_message

      t.timestamps
    end
  end
end
