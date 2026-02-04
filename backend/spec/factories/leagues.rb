FactoryBot.define do
  factory :league do
    name { "MyString" }
    team_count { 1 }
    auction_budget { 1 }
    keeper_limit { 1 }
    roster_config { "" }
  end
end
