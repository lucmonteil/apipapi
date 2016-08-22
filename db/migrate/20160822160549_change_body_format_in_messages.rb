class ChangeBodyFormatInMessages < ActiveRecord::Migration[5.0]
  def change
    change_column :messages, :body, :text
  end
end
