FactoryBot.define do
  factory :league do
    name { "Test League" }
    team_count { 12 }
    auction_budget { 260 }
    keeper_limit { 3 }
    roster_config do
      {
        "C" => 2,
        "1B" => 1,
        "2B" => 1,
        "3B" => 1,
        "SS" => 1,
        "MI" => 1,
        "CI" => 1,
        "OF" => 5,
        "UTIL" => 2,
        "SP" => 5,
        "RP" => 3,
        "BENCH" => 0
      }
    end
  end
end
