require "sidekiq/web"

Rails.application.routes.draw do
  resources :sleep_logs, path: "sleep-logs" do
    post "clock-out", on: :member
  end

  resources :follows
  resources :users

  get "/timelines", to: "timelines#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount Sidekiq::Web => "/sidekiq" # access it at http://localhost:3000/sidekiq
end
