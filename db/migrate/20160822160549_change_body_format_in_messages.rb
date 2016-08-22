class ChangeBodyFormatInMessages < ActiveRecord::Migration[5.0]
  def up
    change_column :messages, :body, :string
  end

  def down
    change_column :messages, :body, :text
  end
end
