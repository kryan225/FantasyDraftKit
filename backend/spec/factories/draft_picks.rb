FactoryBot.define do
  factory :draft_pick do
    league { nil }
    team { nil }
    player { nil }
    price { 10 }
    is_keeper { false }
    pick_number { 1 }
    drafted_position { "C" }
  end
end
