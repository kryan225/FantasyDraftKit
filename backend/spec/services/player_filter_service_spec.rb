# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerFilterService do
  # The Player model has a before_save callback (sync_drafted_status) that sets
  # is_drafted based on team_id presence. Drafted players need a real team_id.
  let!(:league) { create(:league, name: "Test League") }
  let!(:team) { create(:team, league: league, name: "Team 1", budget_remaining: 260) }

  let!(:available_catcher) do
    create(:player,
      name: "John Doe", positions: "C", mlb_team: "NYY",
      calculated_value: 25, interested: false,
      projections: { "home_runs" => 15, "batting_average" => 0.260, "at_bats" => 500 })
  end

  let!(:available_first_baseman) do
    create(:player,
      name: "Jane Smith", positions: "1B", mlb_team: "BOS",
      calculated_value: 30, interested: true,
      projections: { "home_runs" => 35, "batting_average" => 0.290, "at_bats" => 550 })
  end

  let!(:available_outfielder) do
    create(:player,
      name: "Bob Johnson", positions: "OF", mlb_team: "LAD",
      calculated_value: 20, interested: false,
      projections: { "home_runs" => 25, "stolen_bases" => 30, "batting_average" => 0.275, "at_bats" => 520 })
  end

  let!(:available_pitcher) do
    create(:player,
      name: "Mike Wilson", positions: "SP", mlb_team: "NYM",
      calculated_value: 15, interested: true,
      projections: { "wins" => 14, "strikeouts" => 200, "era" => 3.15, "whip" => 1.10, "innings_pitched" => 190 })
  end

  let!(:drafted_catcher) do
    create(:player,
      name: "Tom Brown", positions: "C", mlb_team: "CHC",
      calculated_value: 22, team: team, interested: false,
      projections: { "home_runs" => 20, "batting_average" => 0.245 })
  end

  let!(:multi_position_player) do
    create(:player,
      name: "Alex Multi", positions: "1B/OF", mlb_team: "SF",
      calculated_value: 18, interested: false,
      projections: { "home_runs" => 22, "stolen_bases" => 12, "batting_average" => 0.270 })
  end

  def build_params(hash = {})
    ActionController::Parameters.new(hash)
  end

  describe "#call" do
    context "with no params (default behavior)" do
      it "returns only available players" do
        result = described_class.new(build_params).call
        expect(result).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher, multi_position_player)
        expect(result).not_to include(drafted_catcher)
      end

      it "sorts by calculated_value descending" do
        result = described_class.new(build_params).call
        values = result.map(&:calculated_value)
        expect(values).to eq(values.sort.reverse)
      end
    end

    context "position filter" do
      it "filters by single position" do
        result = described_class.new(build_params(position: "C")).call
        expect(result).to include(available_catcher)
        expect(result).not_to include(available_first_baseman, available_outfielder, available_pitcher)
      end

      it "ignores position filter when blank" do
        result = described_class.new(build_params(position: "")).call
        expect(result.count).to eq(5) # all available players
      end
    end

    context "search filter" do
      it "filters by partial name match (case insensitive)" do
        result = described_class.new(build_params(search: "john")).call
        expect(result).to include(available_catcher, available_outfielder) # John Doe, Bob Johnson
        expect(result).not_to include(available_first_baseman, available_pitcher)
      end

      it "filters by exact name" do
        result = described_class.new(build_params(search: "Jane Smith")).call
        expect(result).to include(available_first_baseman)
        expect(result.count).to eq(1)
      end

      it "returns empty for non-matching search" do
        result = described_class.new(build_params(search: "NonExistent")).call
        expect(result).to be_empty
      end

      it "ignores search filter when blank" do
        result = described_class.new(build_params(search: "")).call
        expect(result.count).to eq(5) # all available players
      end
    end

    context "drafted status filter" do
      it "defaults to available players when no drafted param" do
        result = described_class.new(build_params).call
        expect(result).not_to include(drafted_catcher)
      end

      it "shows all players when drafted is empty string" do
        result = described_class.new(build_params(drafted: "")).call
        expect(result).to include(available_catcher, drafted_catcher)
      end

      it "shows only drafted players when drafted=true" do
        result = described_class.new(build_params(drafted: "true")).call
        expect(result).to include(drafted_catcher)
        expect(result).not_to include(available_catcher, available_first_baseman)
      end

      it "shows only available players when drafted=false" do
        result = described_class.new(build_params(drafted: "false")).call
        expect(result).to include(available_catcher)
        expect(result).not_to include(drafted_catcher)
      end
    end

    context "interested filter" do
      it "shows only interested players when interested=true" do
        result = described_class.new(build_params(interested: "true")).call
        expect(result).to include(available_first_baseman, available_pitcher)
        expect(result).not_to include(available_catcher, available_outfielder)
      end

      it "shows all available players when interested is not set" do
        result = described_class.new(build_params).call
        expect(result).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher)
      end
    end

    context "multi_position filter" do
      it "shows only multi-position players when multi_position=true" do
        result = described_class.new(build_params(multi_position: "true")).call
        expect(result).to include(multi_position_player)
        expect(result).not_to include(available_catcher, available_first_baseman)
      end

      it "shows all available players when multi_position is not set" do
        result = described_class.new(build_params).call
        expect(result).to include(multi_position_player, available_catcher)
      end
    end

    context "combined filters" do
      it "combines position and drafted status" do
        result = described_class.new(build_params(position: "C", drafted: "")).call
        expect(result).to include(available_catcher, drafted_catcher)
        expect(result).not_to include(available_first_baseman)
      end

      it "combines search and position" do
        result = described_class.new(build_params(search: "john", position: "C")).call
        expect(result).to include(available_catcher)
        expect(result).not_to include(available_outfielder) # Bob Johnson is OF, not C
      end

      it "combines interested and position" do
        result = described_class.new(build_params(interested: "true", position: "SP")).call
        expect(result).to include(available_pitcher)
        expect(result).not_to include(available_first_baseman) # interested but 1B
      end
    end

    context "sorting by standard columns" do
      it "sorts by name ascending" do
        result = described_class.new(build_params(sort: "name", direction: "asc")).call
        expect(result.first.name).to eq("Alex Multi")
      end

      it "sorts by name descending" do
        result = described_class.new(build_params(sort: "name", direction: "desc")).call
        expect(result.first.name).to eq("Mike Wilson")
      end

      it "sorts by positions" do
        result = described_class.new(build_params(sort: "positions", direction: "asc")).call
        expect(result.first.positions).to eq("1B")
      end

      it "sorts by mlb_team" do
        result = described_class.new(build_params(sort: "mlb_team", direction: "asc")).call
        expect(result.first.mlb_team).to eq("BOS")
      end

      it "sorts by calculated_value ascending" do
        result = described_class.new(build_params(sort: "calculated_value", direction: "asc")).call
        expect(result.first).to eq(available_pitcher) # $15
      end

      it "sorts by calculated_value with NULLS LAST" do
        null_player = create(:player, name: "Null Val", positions: "OF", calculated_value: nil)
        result = described_class.new(build_params(sort: "calculated_value", direction: "desc")).call.to_a
        expect(result.last).to eq(null_player)
      end
    end

    context "sorting by JSONB columns" do
      it "sorts by home_runs descending" do
        result = described_class.new(build_params(sort: "home_runs", direction: "desc")).call
        expect(result.first).to eq(available_first_baseman) # 35 HR
      end

      it "sorts by stolen_bases ascending" do
        # multi_position: 12 SB, outfielder: 30 SB → ascending puts multi first
        result = described_class.new(build_params(sort: "stolen_bases", direction: "asc", position: "OF")).call
        of_players = result.select { |p| p.positions.include?("OF") }
        expect(of_players.first).to eq(multi_position_player) # 12 SB
        expect(of_players.last).to eq(available_outfielder)   # 30 SB
      end

      it "sorts by batting_average descending" do
        result = described_class.new(build_params(sort: "batting_average", direction: "desc")).call
        expect(result.first).to eq(available_first_baseman) # .290
      end

      it "sorts by at_bats descending" do
        result = described_class.new(build_params(sort: "at_bats", direction: "desc")).call
        expect(result.first).to eq(available_first_baseman) # 550 AB
      end

      it "sorts by innings_pitched descending" do
        result = described_class.new(build_params(sort: "innings_pitched", direction: "desc", position: "SP")).call
        expect(result.first).to eq(available_pitcher) # 190 IP
      end

      it "sorts by era ascending" do
        result = described_class.new(build_params(sort: "era", direction: "asc", position: "SP")).call
        expect(result.first).to eq(available_pitcher)
      end

      it "sorts by whip ascending" do
        result = described_class.new(build_params(sort: "whip", direction: "asc", position: "SP")).call
        expect(result.first).to eq(available_pitcher)
      end
    end

    context "sort edge cases" do
      it "falls back to calculated_value desc for unknown sort column" do
        result = described_class.new(build_params(sort: "invalid_column")).call
        values = result.map(&:calculated_value)
        expect(values).to eq(values.sort.reverse)
      end

      it "ignores invalid direction and defaults to desc" do
        result = described_class.new(build_params(sort: "calculated_value", direction: "DROP TABLE")).call
        values = result.map(&:calculated_value)
        expect(values).to eq(values.sort.reverse)
      end

      it "does not allow SQL injection via sort column" do
        # Unrecognized sort columns fall back to default — never interpolated into SQL
        expect {
          described_class.new(build_params(sort: "name; DROP TABLE players; --")).call.to_a
        }.not_to raise_error
      end
    end

    context "return type" do
      it "returns an ActiveRecord::Relation" do
        result = described_class.new(build_params).call
        expect(result).to be_a(ActiveRecord::Relation)
      end
    end
  end
end
