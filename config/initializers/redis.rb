redis_config = RedisClient.config(host: ENV.fetch("REDIS_HOST", "127.0.0.1"), port: 6379, db: ENV.fetch("REDIS_DB", 0))
REDIS = redis_config.new_pool(timeout: ENV.fetch("REDIS_TIMEOUT", 0.5).to_f, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))
