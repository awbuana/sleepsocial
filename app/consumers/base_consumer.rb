class BaseConsumer < Racecar::Consumer
  def perform(message)
    raise NotImplementedError
  end

  def process(message)
    Rails.logger.info(message: message.value, topic: message.topic, partition: message.partition, retry_count: message.retries_count)
    perform(message)
  rescue => e
    Rails.logger.error(error: e.message, error_class: e.class, backtrace: e.backtrace.take(15).join("\n"))
    raise e
  end
end
