class FeedComputeJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find_by(user_id)
    return unless user

    user.following.select(:id).order(:id).find_in_batches do |following|
      args = following.map { |fol| [ user.id, fol.id ] }
      Sidekiq::Client.push_bulk("class" => FeedBackfillJob, "args" => args)
    end
  end
end
