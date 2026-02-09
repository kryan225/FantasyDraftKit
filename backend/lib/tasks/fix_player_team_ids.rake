namespace :data do
  desc "Fix player team_ids to match their draft picks"
  task fix_player_team_ids: :environment do
    puts "Fixing player team_ids..."

    fixed_count = 0
    DraftPick.includes(:player, :team).find_each do |pick|
      if pick.player.team_id != pick.team_id
        puts "  Fixing player #{pick.player.name}: team_id #{pick.player.team_id.inspect} -> #{pick.team_id} (#{pick.team.name})"
        pick.player.update_columns(team_id: pick.team_id, is_drafted: true)
        fixed_count += 1
      end
    end

    puts "Fixed #{fixed_count} players"
    puts "Done!"
  end
end
