class CreateLeagues < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues do |t|
      t.string :name
      t.integer :team_count
      t.integer :auction_budget
      t.integer :keeper_limit
      t.jsonb :roster_config

      t.timestamps
    end
  end
end
