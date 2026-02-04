class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name
      t.integer :budget_remaining

      t.timestamps
    end
  end
end
