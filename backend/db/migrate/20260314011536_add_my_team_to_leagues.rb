class AddMyTeamToLeagues < ActiveRecord::Migration[8.1]
  def change
    add_reference :leagues, :my_team, null: true, foreign_key: { to_table: :teams }
  end
end
