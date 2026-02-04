class CreateDraftPicks < ActiveRecord::Migration[8.1]
  def change
    create_table :draft_picks do |t|
      t.references :league, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :price
      t.boolean :is_keeper
      t.integer :pick_number

      t.timestamps
    end
  end
end
