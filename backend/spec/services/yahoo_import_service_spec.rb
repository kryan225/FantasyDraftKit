# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YahooImportService do
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
      write_csv('yahoo_hitters.csv', <<~CSV)
        All Players - Batters
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,Aaron Judge OF | NYY,570,115,160,80,30,1,49,120,75,170,5,2,0.281,0.390,0.590,1
        FA,"Marcus Semien 2B,SS | TEX",580,95,155,90,28,2,25,85,55,110,15,4,0.267,0.340,0.470,15
      CSV
    end

    it 'imports hitters from Yahoo format' do
      result = described_class.new(hitter_csv).call

      expect(result[:imported]).to eq(2)
      expect(result[:merged]).to eq(0)

      judge = Player.find_by(name: "Aaron Judge")
      expect(judge).to be_present
      expect(judge.positions).to eq("OF")
      expect(judge.mlb_team).to eq("NYY")
      expect(judge.projections["home_runs"]).to eq(49)
      expect(judge.projections["batting_average"]).to eq(0.281)

      semien = Player.find_by(name: "Marcus Semien")
      expect(semien.positions).to eq("2B,SS")
    end

    it 'merges two-way players across hitter and pitcher CSVs' do
      # First import: hitter side
      hitter_side = write_csv('ohtani_hit.csv', <<~CSV)
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,"Shohei Ohtani U,SP | LAD",530,100,150,70,30,2,48,110,80,160,25,5,0.283,0.380,0.580,1
      CSV
      described_class.new(hitter_side).call

      # Second import: pitcher side
      pitcher_side = write_csv('ohtani_pitch.csv', <<~CSV)
        Avail,Player,INNs,APP,GS,QS,CG,W,L,S,BS,HD,K,BB,H,ERA,WHIP,Rank
        FA,"Shohei Ohtani U,SP | LAD",130,23,23,12,0,10,4,0,0,0,170,30,95,2.50,0.96,1
      CSV
      result = described_class.new(pitcher_side).call

      expect(result[:merged]).to eq(1)
      expect(result[:merged_names]).to include("Shohei Ohtani")

      ohtani = Player.find_by(name: "Shohei Ohtani")
      expect(ohtani.positions).to eq("UTIL,SP")
      # Both hitter and pitcher stats present
      expect(ohtani.projections["home_runs"]).to eq(48)
      expect(ohtani.projections["wins"]).to eq(10)
    end
  end

  describe 'pitcher CSV import' do
    let(:pitcher_csv) do
      write_csv('yahoo_pitchers.csv', <<~CSV)
        Avail,Player,INNs,APP,GS,QS,CG,W,L,S,BS,HD,K,BB,H,ERA,WHIP,Rank
        FA,Gerrit Cole SP | NYY,195.0,32,32,18,1,14,7,0,0,0,220,45,160,3.10,1.05,1
      CSV
    end

    it 'imports pitchers from Yahoo format' do
      result = described_class.new(pitcher_csv).call

      expect(result[:imported]).to eq(1)

      cole = Player.find_by(name: "Gerrit Cole")
      expect(cole.positions).to eq("SP")
      expect(cole.projections["innings_pitched"]).to eq(195.0)
      expect(cole.projections["era"]).to eq(3.10)
      expect(cole.projections["strikeouts"]).to eq(220)
    end
  end

  describe 'position parsing' do
    it 'converts U to UTIL' do
      csv = write_csv('util.csv', <<~CSV)
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,Test Player U | NYY,500,80,130,70,25,1,20,75,50,120,10,3,0.260,0.330,0.450,50
      CSV
      described_class.new(csv).call

      player = Player.find_by(name: "Test Player")
      expect(player.positions).to eq("UTIL")
    end

    it 'strips DH from positions' do
      csv = write_csv('dh.csv', <<~CSV)
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,"Test Player OF,DH | NYY",500,80,130,70,25,1,20,75,50,120,10,3,0.260,0.330,0.450,50
      CSV
      described_class.new(csv).call

      player = Player.find_by(name: "Test Player")
      expect(player.positions).to eq("OF")
    end

    it 'skips rows with unparseable player info' do
      csv = write_csv('bad_info.csv', <<~CSV)
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,BadData,500,80,130,70,25,1,20,75,50,120,10,3,0.260,0.330,0.450,50
      CSV
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(0)
    end
  end

  describe 'edge cases' do
    it 'skips title rows' do
      csv = write_csv('with_title.csv', <<~CSV)
        All Players - Batters
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,Test Player OF | NYY,500,80,130,70,25,1,20,75,50,120,10,3,0.260,0.330,0.450,50
      CSV
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(1)
    end

    it 'skips rows with empty player column' do
      csv = write_csv('empty_player.csv', <<~CSV)
        Avail,Player,AB,R,H,1B,2B,3B,HR,RBI,BB,K,SB,CS,AVG,OBP,SLG,Rank
        FA,,500,80,130,70,25,1,20,75,50,120,10,3,0.260,0.330,0.450,50
      CSV
      result = described_class.new(csv).call
      expect(result[:imported]).to eq(0)
    end
  end
end
