FactoryBot.define do
  factory :draft_pick do
    league { nil }
    team { nil }
    player { nil }
    price { 1 }
    is_keeper { false }
    pick_number { 1 }
  end
end
