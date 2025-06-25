server:
	bin/rails s

sidekiq:
	bundle exec sidekiq -C config/sidekiq.yml

feed-consumer:
	bundle exec racecar FeedUpdatesConsumer

insert-consumer:
	bundle exec racecar SleepLogCreatedConsumer