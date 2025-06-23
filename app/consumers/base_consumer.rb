class BaseConsumer < Racecar::Consumer
  def perform(message)
    raise NotImplementedError
  end

  def process(message)
    ActiveSupport::Notifications.instrument("consumer_job", message: message) do |payload|
      perform(message)
    end
  end

  ActiveSupport::Notifications.subscribe "consumer_job" do |*data|
    event = ActiveSupport::Notifications::Event.new(*data)
    payload = event.payload
    message = payload[:message]
    exception = payload[:exception_object]
    tags = {message: message.value, partition: message.partition, topic: message.partition, duration_ms: event.duration}

    if exception
      Rails.logger.error(error: exception.message, backtrace: exception.backtrace.take(15).join("\n"), **tags)
    else
      Rails.logger.info(**tags)
    end
  end
end
