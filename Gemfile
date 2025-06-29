source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# Use sqlite3 as the database for Active Record
gem "mysql2", ">= 0.5.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

gem "redis-client"

gem "active_model_serializers", "~> 0.10"
gem "activerecord_cursor_paginate"

gem "lograge"
gem "logstash-event"

gem "identity_cache", "~> 1.6.3"
gem "cityhash"
gem "dalli"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

gem "racecar"

group :development, :test do
  gem "pry"

  gem "rspec-rails", "~> 8.0.0"

  gem "shoulda-matchers", "~> 6.0"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "faker"

  gem "dotenv"

  gem "factory_bot_rails"

  gem "timecop"

  gem "json-schema"
end

gem "simplecov", require: false, group: :test
