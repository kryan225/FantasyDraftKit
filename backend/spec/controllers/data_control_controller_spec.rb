require 'rails_helper'

RSpec.describe DataControlController, type: :controller do
  let(:league) { create(:league) }

  describe 'GET #show' do
    it 'displays data control page' do
      get :show, params: { league_id: league.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #import_players' do
    context 'with hitter CSV' do
      let(:hitter_csv) do
        CSV.generate do |csv|
          csv << ["All Players", "Projections Standard Categories"]
          csv << ["Avail", "Player", "AB", "R", "H", "1B", "2B", "3B", "HR", "RBI", "BB", "K", "SB", "CS", "AVG", "OBP", "SLG", "Rank"]
          csv << ["", "Aaron Judge OF | NYY", "600", "120", "180", "90", "30", "2", "58", "140", "80", "150", "5", "2", "0.300", "0.400", "0.650", "1"]
          csv << ["", "Juan Soto OF | NYY", "550", "110", "165", "75", "28", "1", "42", "115", "120", "100", "2", "1", "0.300", "0.420", "0.600", "2"]
        end
      end

      it 'imports hitters with correct statistics' do
        file = Tempfile.new(['hitters', '.csv'])
        file.write(hitter_csv)
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        expect {
          post :import_players, params: { league_id: league.id, file: uploaded_file }
        }.to change(Player, :count).by(2)

        aaron_judge = Player.find_by(name: "Aaron Judge")
        expect(aaron_judge).to be_present
        expect(aaron_judge.positions).to eq("OF")
        expect(aaron_judge.mlb_team).to eq("NYY")
        expect(aaron_judge.projections["at_bats"]).to eq(600)
        expect(aaron_judge.projections["home_runs"]).to eq(58)
        expect(aaron_judge.projections["rbi"]).to eq(140)
        expect(aaron_judge.projections["stolen_bases"]).to eq(5)
        expect(aaron_judge.projections["batting_average"]).to eq(0.300)

        # Should not have pitcher stats
        expect(aaron_judge.projections["innings_pitched"]).to be_nil
        expect(aaron_judge.projections["era"]).to be_nil

        file.close
        file.unlink
      end
    end

    context 'with pitcher CSV' do
      let(:pitcher_csv) do
        CSV.generate do |csv|
          csv << ["All Players", "Projections Standard Categories"]
          csv << ["Avail", "Player", "INNs", "APP", "GS", "QS", "CG", "W", "L", "S", "BS", "HD", "K", "BB", "H", "ERA", "WHIP", "Rank"]
          csv << ["", "Paul Skenes SP | PIT", "181.0", "30", "30", "21", "1", "10", "8", "0", "0", "0", "204", "40", "135", "2.39", "0.97", "10"]
          csv << ["", "Garrett Crochet SP | BOS", "154.0", "26", "26", "17", "1", "13", "5", "0", "0", "0", "190", "36", "142", "3.27", "1.16", "11"]
        end
      end

      it 'imports pitchers with correct statistics' do
        file = Tempfile.new(['pitchers', '.csv'])
        file.write(pitcher_csv)
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        expect {
          post :import_players, params: { league_id: league.id, file: uploaded_file }
        }.to change(Player, :count).by(2)

        paul_skenes = Player.find_by(name: "Paul Skenes")
        expect(paul_skenes).to be_present
        expect(paul_skenes.positions).to eq("SP")
        expect(paul_skenes.mlb_team).to eq("PIT")
        expect(paul_skenes.projections["innings_pitched"]).to eq(181.0)
        expect(paul_skenes.projections["wins"]).to eq(10)
        expect(paul_skenes.projections["saves"]).to eq(0)
        expect(paul_skenes.projections["strikeouts"]).to eq(204)
        expect(paul_skenes.projections["era"]).to eq(2.39)
        expect(paul_skenes.projections["whip"]).to eq(0.97)

        # Should not have hitter stats
        expect(paul_skenes.projections["at_bats"]).to be_nil
        expect(paul_skenes.projections["home_runs"]).to be_nil
        expect(paul_skenes.projections["batting_average"]).to be_nil

        file.close
        file.unlink
      end
    end

    context 'with mixed CSV (both pitchers and hitters)' do
      let(:mixed_csv) do
        CSV.generate do |csv|
          csv << ["All Players", "Projections Standard Categories"]
          # This header will be for hitters
          csv << ["Avail", "Player", "AB", "R", "H", "1B", "2B", "3B", "HR", "RBI", "BB", "K", "SB", "CS", "AVG", "OBP", "SLG", "Rank"]
          csv << ["", "Aaron Judge OF | NYY", "600", "120", "180", "90", "30", "2", "58", "140", "80", "150", "5", "2", "0.300", "0.400", "0.650", "1"]
        end
      end

      it 'handles CSV with only one type gracefully' do
        file = Tempfile.new(['mixed', '.csv'])
        file.write(mixed_csv)
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        expect {
          post :import_players, params: { league_id: league.id, file: uploaded_file }
        }.to change(Player, :count).by(1)

        file.close
        file.unlink
      end
    end

    context 'with two-way player (Shohei Ohtani)' do
      let(:two_way_csv) do
        CSV.generate do |csv|
          csv << ["All Players", "Projections Standard Categories"]
          csv << ["Avail", "Player", "INNs", "APP", "GS", "QS", "CG", "W", "L", "S", "BS", "HD", "K", "BB", "H", "ERA", "WHIP", "Rank"]
          csv << ["", "Shohei Ohtani UTIL,SP | LAD", "103.0", "26", "26", "5", "0", "6", "2", "0", "0", "0", "132", "21", "74", "2.80", "0.92", "3"]
        end
      end

      it 'treats player as pitcher when SP is in positions' do
        file = Tempfile.new(['two_way', '.csv'])
        file.write(two_way_csv)
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        expect {
          post :import_players, params: { league_id: league.id, file: uploaded_file }
        }.to change(Player, :count).by(1)

        shohei = Player.find_by(name: "Shohei Ohtani")
        expect(shohei).to be_present
        expect(shohei.positions).to include("SP")
        expect(shohei.positions).to include("UTIL")

        # Should have pitcher stats since SP is in positions
        expect(shohei.projections["innings_pitched"]).to eq(103.0)
        expect(shohei.projections["era"]).to eq(2.80)

        file.close
        file.unlink
      end
    end

    context 'error handling' do
      it 'shows error when no file is provided' do
        post :import_players, params: { league_id: league.id }
        expect(response).to redirect_to(league_data_control_path(league))
        expect(flash[:alert]).to include("Please select a CSV file")
      end

      it 'skips existing players' do
        create(:player, name: "Aaron Judge", mlb_team: "NYY")

        hitter_csv = CSV.generate do |csv|
          csv << ["All Players", "Projections Standard Categories"]
          csv << ["Avail", "Player", "AB", "R", "H", "1B", "2B", "3B", "HR", "RBI", "BB", "K", "SB", "CS", "AVG", "OBP", "SLG", "Rank"]
          csv << ["", "Aaron Judge OF | NYY", "600", "120", "180", "90", "30", "2", "58", "140", "80", "150", "5", "2", "0.300", "0.400", "0.650", "1"]
        end

        file = Tempfile.new(['existing', '.csv'])
        file.write(hitter_csv)
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

        expect {
          post :import_players, params: { league_id: league.id, file: uploaded_file }
        }.not_to change(Player, :count)

        expect(flash[:notice]).to include("Skipped 1 existing players")

        file.close
        file.unlink
      end
    end
  end

  describe 'POST #undraft_all_players' do
    it 'undrafts all players and deletes draft picks' do
      team = create(:team, league: league)
      player = create(:player, is_drafted: true, positions: "OF")
      create(:draft_pick, league: league, team: team, player: player, drafted_position: "OF", price: 10)

      expect {
        post :undraft_all_players, params: { league_id: league.id }
      }.to change(DraftPick, :count).by(-1)

      player.reload
      expect(player.is_drafted).to be false
    end
  end

  describe 'POST #delete_all_players' do
    it 'deletes all players' do
      create(:player)
      create(:player)

      expect {
        post :delete_all_players, params: { league_id: league.id }
      }.to change(Player, :count).by(-2)

      expect(flash[:notice]).to include("Successfully deleted 2 players")
    end

    it 'cascades delete to draft picks' do
      team = create(:team, league: league)
      player = create(:player, positions: "OF")
      draft_pick = create(:draft_pick, league: league, team: team, player: player, drafted_position: "OF", price: 10)

      expect {
        post :delete_all_players, params: { league_id: league.id }
      }.to change(Player, :count).by(-1)
         .and change(DraftPick, :count).by(-1)

      expect(DraftPick.find_by(id: draft_pick.id)).to be_nil
    end
  end
end
