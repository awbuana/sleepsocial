FactoryBot.define do
  factory :user do
    name { Faker::Name.unique.name }
    num_following { 0 }
    num_followers { 0 }
  end
end
