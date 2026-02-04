class CreateKeeperHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :keeper_histories do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :year
      t.integer :price

      t.timestamps
    end
  end
end
