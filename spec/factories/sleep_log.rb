FactoryBot.define do
  factory :sleep_log do
    association :user, factory: :user
    clock_in { 8.hours.ago } # Default clock_in to 8 hours ago for convenience
    clock_out { Time.current } # Default clock_out to now

    trait :invalid_times do
      clock_in { Time.current }
      clock_out { 1.hour.ago } # clock_out before clock_in
    end

    trait :no_clock_out do
      clock_out { nil }
    end

    trait :short_sleep do
      clock_in { 1.hour.ago }
      clock_out { Time.current }
    end

    trait :long_sleep do
      clock_in { 10.hours.ago }
      clock_out { Time.current }
    end
  end
end
