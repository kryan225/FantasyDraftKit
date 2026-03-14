# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FangraphsImportService do
  let(:tmp_dir) { Rails.root.join('tmp', 'test_csvs') }

  before { FileUtils.mkdir_p(tmp_dir) }
  after { FileUtils.rm_rf(tmp_dir) }

  def write_csv(filename, content)
    path = tmp_dir.join(filename)
    File.write(path, content)
    path.to_s
  end

  describe 'hitter CSV import' do
    let(:hitter_csv) do
      write_csv('hitters.csv', <<~CSV)
        Name,Team,PA,AB,H,1B,2B,3B,HR,R,RBI,BB,SO,SB,CS,AVG,OBP,SLG,wOBA,wRC+,WAR,FPTS,ADP,K%,BB%,InterSD,IntraSD,Vol,Skew,PlayerId
        Aaron Judge,NYY,650,570,160,80,30,1,49,115,120,75,170,5,2,0.281,0.390,0.590,0.410,170,7.5,850.5,3.2,26.2,11.5,45.2,38.1,3.8,0.2,28476
      CSV
    end

    it 'imports a new hitter' do
      result = described_class.new(hitter_csv).call

      expect(result[:imported]).to eq(1)
      expect(result[:merged]).to eq(0)

      player = Player.find_by(name: "Aaron Judge")
      expect(player).to be_present
      expect(player.mlb_team).to eq("NYY")
      expect(player.positions).to eq("UTIL")
      expect(player.projections["home_runs"]).to eq(49.0)
      expect(player.projections["fpts"]).to eq(850.5)
      expect(player.projections["adp"]).to eq(3.2)
      expect(player.projections["vol"]).to eq(3.8)
      expect(player.projections["fangraphs_id"]).to eq("28476")
    end

    it 'merges projections for existing player' do
      create(:player, name: "Aaron Judge", mlb_team: "NYY", positions: "OF",
                      projections: { "at_bats" => 570, "home_runs" => 45 })

      result = described_class.new(hitter_csv).call

      expect(result[:imported]).to eq(0)
      expect(result[:merged]).to eq(1)
      expect(result[:merged_names]).to eq(["Aaron Judge"])

      player = Player.find_by(name: "Aaron Judge")
      expect(player.positions).to eq("OF") # positions unchanged
      expect(player.projections["fpts"]).to eq(850.5) # new data merged
      expect(player.projections["home_runs"]).to eq(49.0) # overwritten by FanGraphs data
    end
  end

  describe 'pitcher CSV import' do
    let(:pitcher_csv) do
      write_csv('pitchers.csv', <<~CSV)
        Name,Team,IP,G,GS,QS,W,L,SV,BS,HLD,SO,BB,H,ERA,WHIP,FPTS,ADP,FIP,WAR,K%,BB%,InterSD,IntraSD,Vol,Skew,PlayerId
        Gerrit Cole,NYY,195.0,32,32,18,14,7,0,0,0,220,45,160,3.10,1.05,680.3,12.5,3.00,5.2,28.5,5.8,32.1,28.5,2.5,-0.3,13125
      CSV
    end

    it 'imports a new pitcher' do
      result = described_class.new(pitcher_csv).call

      expect(result[:imported]).to eq(1)

      player = Player.find_by(name: "Gerrit Cole")
      expect(player.positions).to eq("SP")
      expect(player.projections["innings_pitched"]).to eq(195.0)
      expect(player.projections["fip"]).to eq(3.00)
      expect(player.projections["era"]).to eq(3.10)
      expect(player.projections["vol"]).to eq(2.5)
    end
  end

  describe 'auto-detection' do
    it 'detects hitter CSV from PA header' do
      csv = write_csv('detect_hitter.csv', "Name,Team,PA,AB,HR\nTest,NYY,500,450,30\n")
      # Should not raise
      expect { described_class.new(csv).call }.not_to raise_error
    end

    it 'detects pitcher CSV from IP header' do
      csv = write_csv('detect_pitcher.csv', "Name,Team,IP,W,SO\nTest,NYY,180,12,200\n")
      expect { described_class.new(csv).call }.not_to raise_error
    end

    it 'raises on unrecognized header' do
      csv = write_csv('bad.csv', "Name,Team,XYZ\nTest,NYY,100\n")
      expect { described_class.new(csv).call }.to raise_error(RuntimeError, /Unable to detect CSV type/)
    end
  end

  describe 'edge cases' do
    it 'skips rows with blank player name' do
      csv = write_csv('blank_name.csv', "Name,Team,PA,AB,HR\n,NYY,500,450,30\n")
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(0)
    end

    it 'skips rows with blank team' do
      csv = write_csv('blank_team.csv', "Name,Team,PA,AB,HR\nTest,,500,450,30\n")
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(0)
    end

    it 'handles BOM-encoded CSV' do
      content = "\xEF\xBB\xBFName,Team,PA,AB,HR\nTest Player,NYY,500,450,30\n"
      csv = write_csv('bom.csv', content)
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(1)
      expect(Player.find_by(name: "Test Player")).to be_present
    end

    it 'uses NameASCII when available' do
      csv = write_csv('ascii.csv', "Name,NameASCII,Team,PA,AB,HR\nJosé Ramírez,Jose Ramirez,CLE,600,540,28\n")
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(1)
      expect(Player.find_by(name: "Jose Ramirez")).to be_present
    end

    it 'raises on malformed CSV' do
      csv = write_csv('malformed.csv', "Name,Team,PA\n\"unclosed quote,NYY,500\n")
      expect { described_class.new(csv).call }.to raise_error(CSV::MalformedCSVError)
    end
  end
end
