# README

Sleepsocial is designed to allow users to log their sleep, share it, and view sleep-related data such as feeds and leaderboards.

### Ruby version

ruby-3.3.1

### System dependencies

- MySQL 8
- Redis 7
- Memcached
- Kafka

setup docker compose
```
docker-compose up
```

### Configuration

```
cp env.sample .env
```

### Database creation

```
rails db:create
```

### Database initialization

```
rails db:migrate
```

### How to run the test suite

```
bundle exec rspec
```

### How to run services

run server
```
make server
```

run feed consumer
```
make feed-consumer
```

run fanout log consumer
```
make fanout-consumer
```

# Documentation

- API Documentation [link](DOCUMENTATION/API.yaml)
- Feature Requirements [link](DOCUMENTATION/FEATURE.md)
- System Design [link](DOCUMENTATION/SYSTEM-DESIGN.md)
- Performance Test [link](DOCUMENTATION/PERFORMANCE-TEST.md)
