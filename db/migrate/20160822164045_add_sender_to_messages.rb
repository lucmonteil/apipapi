class AddSenderToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :sender, :boolean
  end
end
