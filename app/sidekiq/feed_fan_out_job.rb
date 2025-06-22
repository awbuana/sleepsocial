class FeedFanOutJob
  include Sidekiq::Job

  def perform(sleep_log_id)
    sleep_log = SleepLog.find_by(id: sleep_log_id)
    return unless sleep_log

    user = sleep_log.user

    user.followers.select(:id).find_in_batches do | users |
      args = users.map{|user| [user.id, sleep_log_id]}
      Sidekiq::Client.push_bulk('class' => FeedInsertJob, 'args' => args)
    end
  end
end
