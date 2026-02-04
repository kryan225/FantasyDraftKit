FactoryBot.define do
  factory :player do
    name { "MyString" }
    positions { "MyString" }
    mlb_team { "MyString" }
    projections { "" }
    calculated_value { "9.99" }
    is_drafted { false }
  end
end
