class ReplaceInterestedWithInterestLevel < ActiveRecord::Migration[8.1]
  def up
    add_column :players, :interest_level, :integer, default: 0, null: false

    # Migrate existing boolean interest flag to level 1
    Player.where(interested: true).update_all(interest_level: 1)

    remove_column :players, :interested
  end

  def down
    add_column :players, :interested, :boolean, default: false, null: false

    Player.where("interest_level > 0").update_all(interested: true)

    remove_column :players, :interest_level
  end
end
