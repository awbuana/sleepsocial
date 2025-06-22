REDIS_HOST = ENV.fetch("REDIS_HOST", "127.0.0.1")
REDIS_DB = ENV.fetch("REDIS_DB", 0)

redis_config = RedisClient.config(host: REDIS_HOST, port: 6379, db: REDIS_DB)
REDIS = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))
