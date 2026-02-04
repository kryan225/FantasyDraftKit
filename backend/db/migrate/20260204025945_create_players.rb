class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name
      t.string :positions
      t.string :mlb_team
      t.jsonb :projections
      t.decimal :calculated_value
      t.boolean :is_drafted

      t.timestamps
    end
  end
end
