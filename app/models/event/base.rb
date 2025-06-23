class Event::Base

  def topic_name
    raise UnimplementedError
  end

  def data
    raise UnimplementedError
  end

  def routing_key
    raise UnimplementedError
  end

  def payload
    {
      event_name: self.class.to_s,
      data: data
    }.to_json
  end
end