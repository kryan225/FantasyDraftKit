# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_04_030001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "draft_picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_keeper"
    t.bigint "league_id", null: false
    t.integer "pick_number"
    t.bigint "player_id", null: false
    t.integer "price"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_draft_picks_on_league_id"
    t.index ["player_id"], name: "index_draft_picks_on_player_id"
    t.index ["team_id"], name: "index_draft_picks_on_team_id"
  end

  create_table "keeper_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.integer "price"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["player_id"], name: "index_keeper_histories_on_player_id"
    t.index ["team_id"], name: "index_keeper_histories_on_team_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.integer "auction_budget"
    t.datetime "created_at", null: false
    t.integer "keeper_limit"
    t.string "name"
    t.jsonb "roster_config"
    t.integer "team_count"
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.decimal "calculated_value"
    t.datetime "created_at", null: false
    t.boolean "is_drafted"
    t.string "mlb_team"
    t.string "name"
    t.string "positions"
    t.jsonb "projections"
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.integer "budget_remaining"
    t.datetime "created_at", null: false
    t.bigint "league_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  add_foreign_key "draft_picks", "leagues"
  add_foreign_key "draft_picks", "players"
  add_foreign_key "draft_picks", "teams"
  add_foreign_key "keeper_histories", "players"
  add_foreign_key "keeper_histories", "teams"
  add_foreign_key "teams", "leagues"
end
