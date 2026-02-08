class AddDraftedPositionToDraftPicks < ActiveRecord::Migration[8.1]
  def change
    add_column :draft_picks, :drafted_position, :string
  end
end
