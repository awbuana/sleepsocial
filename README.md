# README

Sleepsocial is designed to allow users to log their sleep, share it, and view sleep-related data such as feeds and leaderboards.

* Ruby version

ruby-3.3.1

* System dependencies

- MySQL 8
- Redis 7
- Memcached
- Kafka

setup docker compose
```
docker-compose up
```

* Configuration

```
cp env.sample .env
```

* Database creation

```
rails db:create
```

* Database initialization

```
rails db:migrate
```

* How to run the test suite

```
bundle exec rspec
```

* Services (job queues, cache servers, search engines, etc.)

run server
```
make server
```

run feed consumer
```
make feed-consumer
```

run insert log consumer
```
make fanout-consumer
```

# Documentation

- API Documentation [link](DOCUMENTTION/API.yaml)
- Feature Requirements [link](DOCUMENTTION/FEATURE.md)
- System Design [link](DOCUMENTATION/SYSTEM-DESIGN.md)
