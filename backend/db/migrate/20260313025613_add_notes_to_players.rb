class AddNotesToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :notes, :text
  end
end
