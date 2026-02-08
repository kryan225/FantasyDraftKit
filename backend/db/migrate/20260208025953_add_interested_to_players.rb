class AddInterestedToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :interested, :boolean, default: false, null: false
  end
end
