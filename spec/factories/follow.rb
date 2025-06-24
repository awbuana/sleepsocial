FactoryBot.define do
  factory :follow do
    association :user, factory: :user
    association :target_user, factory: :user
  end
end