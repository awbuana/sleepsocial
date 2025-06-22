class SidekiqJobLogger
  include Sidekiq::ServerMiddleware

  def call(job_instance, job_payload, queue)
    begin
      logger.info(msg: 'starting job', jobid: job_instance.jid, payload: job_payload, queue: queue)
      yield
      logger.info(msg: 'completed job', jobid: job_instance.jid, payload: job_payload, queue: queue)
    rescue => ex
      logger.error(ex)
      raise ex
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SidekiqJobLogger
  end
end