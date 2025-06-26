server:
	bin/rails s

feed-consumer:
	bundle exec racecar FeedUpdatesConsumer

fanout-consumer:
	bundle exec racecar SleepLogCreatedConsumer