class AddIsToppedToDraftPicks < ActiveRecord::Migration[8.1]
  def change
    add_column :draft_picks, :is_topped, :boolean, default: false, null: false
  end
end
